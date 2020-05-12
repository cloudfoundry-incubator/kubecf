"""
This Bazel extension contains rule definitions specific to KubeCF.
"""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("//:def.bzl", "project")

def metadata_file_generator(name, file, operator_chart, visibility=None):
    """Generates a metadata file to be embedded with the KubeCF chart.

    Args:
        name: The target name.
        file: The output generated file with the metadata.
        operator_chart: The cf-operator chart file.
        visibility: The visibility to be used by the targets under the macro.
    """
    native.genrule(
        name = name,
        srcs = [],
        outs = [file],
        cmd = "echo 'operatorChartUrl: \"{}\"' > $@".format(operator_chart),
        visibility = visibility,
    )

def _create_sample_values_binary_impl(ctx):
    """A rule to create a sample values.yaml where most values are commented out by default.

    This generates a YAML file, where most values are commented out so that the administrator
    deploying the helm chart will not accidentally override default values in a newer version with
    the default values from an older version when doing an upgrade and reusing a values file.  Any
    values marked as REQUIRED in a comment will be left uncommented, and any values marked as
    HIDDEN in a comment will be omitted from the output.
    """
    ctx.actions.run(
        inputs = [ctx.file.input],
        outputs = [ctx.outputs.output],
        arguments = [ctx.file.input.path, ctx.outputs.output.path],
        progress_message = "Generating sample values.yaml %s" % ctx.outputs.output.path,
        executable = ctx.executable.create_sample_values,
    )

create_sample_values_binary = rule(
    implementation = _create_sample_values_binary_impl,
    attrs = {
        "input": attr.label(allow_single_file = True, mandatory = True),
        "output": attr.output(mandatory = True),
        "create_sample_values": attr.label(
            executable = True,
            cfg = "host",
            allow_files = True,
            default = ":create_sample_values.rb"
        )
    }
)

def _image_list_impl(ctx):
    """A specialized rule for KubeCF to list all the container images being used by the project.

    KubeCF uses many images that are not directly passed during installation, instead, cf-operator
    constructs the image repositories based on the stemcell and BOSH release name and version.
    This rule performs the same calculation by rendering the KubeCF chart with all the permutations
    on the feature flags, i.e. toggling each feature flag on/off.
    This rule also takes into consideration the images listed under the 'releases' key on the
    default values.yaml. The releases that contain an 'image' key is assumed to be a non-BOSH
    release that also needs to be taken into consideration while calculating the output.

    Outputs:
        A JSON file containing the image list, the unique stemcells used by these images, and the
        unique image repository base, e.g. docker.io/cfcontainerization.
    """
    output= ctx.actions.declare_file("{}.json".format(ctx.attr.name))
    outputs = [output]
    script_name = paths.basename(ctx.file._script_tmpl.path).replace(".tmpl", "")
    script = ctx.actions.declare_file(script_name)
    ctx.actions.expand_template(
        output = script,
        substitutions = {
            "[[bosh]]": ctx.executable._bosh_cli.path,
            "[[helm]]": ctx.executable._helm.path,
            "[[chart]]": ctx.file.chart.path,
            "[[output_path]]": output.path,
        },
        template = ctx.file._script_tmpl,
    )
    ctx.actions.run_shell(
        command = "ruby {}".format(script.path),
        inputs = [
            script,
            ctx.file.chart,
        ],
        outputs = outputs,
        tools = [
            ctx.executable._bosh_cli,
            ctx.executable._helm,
        ],
    )
    return [DefaultInfo(files = depset(outputs))]

image_list = rule(
    implementation = _image_list_impl,
    attrs = {
        "chart": attr.label(
            allow_single_file = True,
            default = "//deploy/helm/kubecf:kubecf",
            doc = "The KubeCF chart file",
            mandatory = True,
        ),
        "_bosh_cli": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "@bosh_cli//:binary",
            executable = True,
        ),
        "_helm": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "@helm//:binary",
            executable = True,
        ),
        "_script_tmpl": attr.label(
            allow_single_file = True,
            default = "//rules/kubecf:image_list.tmpl.rb",
        ),
    },
)

def _test_impl(ctx):
    """
    An executable rule to trigger, wait and tail logs for a test.
    """
    script = ctx.actions.declare_file(ctx.attr.name)
    ctx.actions.expand_template(
        output = script,
        substitutions = {
            "[[kubectl]]": ctx.executable._kubectl.path,
            "[[namespace]]": ctx.attr.namespace,
            "[[qjob_name]]": ctx.attr.qjob_name,
        },
        template = ctx.file._script_tmpl,
    )
    runfiles = [
        ctx.executable._kubectl,
    ]
    return [DefaultInfo(
        executable = script,
        runfiles = ctx.runfiles(files = runfiles),
    )]

test = rule(
    implementation = _test_impl,
    attrs = {
        "namespace": attr.string(
            default = project.namespace,
        ),
        "qjob_name": attr.string(
            mandatory = True,
        ),
        "_kubectl": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "@kubectl//:binary",
            executable = True,
        ),
        "_script_tmpl": attr.label(
            allow_single_file = True,
            default = "//rules/kubecf:test.tmpl.sh",
        ),
    },
    executable = True,
)

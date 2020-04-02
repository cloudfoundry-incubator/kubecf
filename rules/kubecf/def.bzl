"""
This Bazel extension contains rule definitions specific to KubeCF.
"""

load("@bazel_skylib//lib:paths.bzl", "paths")

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

def _chart_with_imagelist_impl(ctx):
    """A specialized rule for KubeCF to generate a helm chart including a list of referenced images

    This function runs the kubecf image list and the helm-chart target and repacks them
    including the image_list.json
    """
    output= ctx.actions.declare_file("{}.tgz".format(ctx.attr.name))
    outputs = [output]
    script_name = paths.basename(ctx.file._script_tmpl.path)
    script = ctx.actions.declare_file(script_name)
    ctx.actions.expand_template(
        output = script,
        substitutions = {
        },
        template = ctx.file._script_tmpl,
    )
    ctx.actions.run_shell(
        command = "bash \"{script}\" \"{chart}\" \"{image_list}\" \"{target}\" \"{jq}\"".format(
            script=script.path,
            chart=ctx.file.chart.path,
            image_list=ctx.file.image_list.path,
            target=output.path,
            jq=ctx.executable._jq.path,
            ),
        inputs = [
            script,
            ctx.file.chart,
            ctx.file.image_list
        ],
        outputs = outputs,
        tools = [
            ctx.executable._jq,
        ]
    )
    return [DefaultInfo(files = depset(outputs))]

chart_with_imagelist = rule(
    implementation = _chart_with_imagelist_impl,
    attrs = {
        "chart": attr.label(
            allow_single_file = True,
            default = "//deploy/helm/kubecf:kubecf",
            doc = "The KubeCF chart file",
            mandatory = True,
        ),
        "image_list": attr.label(
            allow_single_file = True,
            default = "//deploy/helm/kubecf:image_list",
            mandatory = True,
        ),
        "_jq": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "@jq//:binary",
            executable = True,
        ),
        "_script_tmpl": attr.label(
            allow_single_file = True,
            default = "//rules/kubecf:release_chart.sh",
        ),
    },
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

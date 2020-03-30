"""
This Bazel extension contains rule definitions specific to KubeCF.
"""

load("@bazel_skylib//lib:paths.bzl", "paths")

def metadata_file_generator(name, file, operator_chart, visibility=None):
    native.genrule(
        name = name,
        srcs = [],
        outs = [file],
        cmd = "echo 'operatorChartUrl: \"{}\"' > $@".format(operator_chart),
        visibility = visibility,
    )

def _image_list_impl(ctx):
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
            mandatory = True,
            default = "//deploy/helm/kubecf:kubecf",
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

def _package_impl(ctx):
    output_filename = "{}-{}.tgz".format(ctx.attr.chart_name, ctx.attr.chart_version)
    output_tgz = ctx.actions.declare_file(output_filename)
    outputs = [output_tgz]
    ctx.actions.run(
        inputs = [] + ctx.files.srcs + ctx.files.tars,
        outputs = outputs,
        tools = [ctx.executable._helm],
        progress_message = "Generating Helm package archive {}".format(output_filename),
        executable = ctx.executable._script,
        env = {
            "PACKAGE_DIR": ctx.attr.package_dir,
            "TARS": " ".join([f.path for f in ctx.files.tars]),
            "HELM": ctx.executable._helm.path,
            "CHART_VERSION": ctx.attr.chart_version,
            "APP_VERSION": ctx.attr.app_version,
            "OUTPUT_FILENAME": output_filename,
            "OUTPUT_TGZ": output_tgz.path,
        },
    )
    return [DefaultInfo(files = depset(outputs))]

_package = rule(
    implementation = _package_impl,
    attrs = {
        "srcs": attr.label_list(
            mandatory = True,
        ),
        "tars": attr.label_list(),
        "package_dir": attr.string(
            mandatory = True,
        ),
        "chart_name": attr.string(
            mandatory = True,
        ),
        "chart_version": attr.string(
            mandatory = True,
        ),
        "app_version": attr.string(
            mandatory = True,
        ),
        "_helm": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "@helm//:helm",
            executable = True,
        ),
        "_script": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "//rules/helm:package.sh",
            executable = True,
        ),
    },
)

def package(**kwargs):
    _package(
        package_dir = native.package_name(),
        **kwargs
    )

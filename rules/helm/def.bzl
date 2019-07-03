def _package_impl(ctx):
    output_filename = "{}-{}.tgz".format(ctx.attr.chart_name, ctx.attr.chart_version)
    output_tgz = ctx.actions.declare_file(output_filename)
    outputs = [output_tgz]
    ctx.actions.run_shell(
        inputs = [] + ctx.files.srcs,
        outputs = outputs,
        tools = [ctx.executable._helm],
        progress_message = "Generating Helm package archive {}".format(output_filename),
        command = """
            {helm} init --client-only > /dev/null
            {helm} package "{package_dir}" \
                --version="{chart_version}" \
                --app-version="{app_version}" > /dev/null
            mv "{output_filename}" "{output_tgz}"
        """.format(
            helm = ctx.executable._helm.path,
            package_dir = ctx.attr.package_dir,
            chart_version = ctx.attr.chart_version,
            app_version = ctx.attr.app_version,
            output_filename = output_filename,
            output_tgz = output_tgz.path,
        ),
    )
    return [DefaultInfo(files = depset(outputs))]

_package = rule(
    implementation = _package_impl,
    attrs = {
        "srcs": attr.label_list(
            mandatory = True,
        ),
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
    },
)

def package(**kwargs):
    _package(
        package_dir = native.package_name(),
        **kwargs
    )

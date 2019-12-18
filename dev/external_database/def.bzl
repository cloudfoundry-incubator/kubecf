load("@bazel_skylib//lib:paths.bzl", "paths")

def _deploy_mysql_impl(ctx):
    template_name = paths.basename(ctx.file._script_template.short_path)
    script = ctx.actions.declare_file("rendered_{}".format(template_name))

    ctx.actions.expand_template(
        template = ctx.file._script_template,
        output = script,
        substitutions = {
            "{MYSQL_CHART}": ctx.file._mysql_chart.path,
            "{HELM}": ctx.executable._helm.short_path,
            "{KUBECTL}": ctx.executable._kubectl.short_path,
        },
        is_executable = True,
    )

    runfiles = [
        ctx.file._mysql_chart,
        ctx.executable._helm,
        ctx.executable._kubectl,
    ]
    return [DefaultInfo(
        executable = script,
        runfiles = ctx.runfiles(files = runfiles),
    )]

deploy_mysql = rule(
    implementation = _deploy_mysql_impl,
    attrs = {
        "_mysql_chart": attr.label(
            allow_single_file = True,
            default = "@mysql_chart//file",
        ),
        "_helm": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "@helm//:binary",
            executable = True,
        ),
        "_kubectl": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "@kubectl//:binary",
            executable = True,
        ),
        "_script_template": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "//dev/external_database:deploy_mysql.sh",
        ),
    },
    executable = True,
)

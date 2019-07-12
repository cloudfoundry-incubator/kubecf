def _kubectl_impl(ctx):
    executable = ctx.actions.declare_file(ctx.attr.name)
    contents = """
        set -o errexit
        export KUBECTL="{kubectl}"
        export RESOURCE="{resource}"
        export NAMESPACE="{namespace}"
        "{script}"
    """.format(
        kubectl = ctx.executable._kubectl.path,
        resource = ctx.file.resource.short_path,
        namespace = ctx.attr.namespace,
        script = ctx.executable._script.path,
    )
    ctx.actions.write(executable, contents, is_executable = True)
    runfiles = [
        ctx.executable._kubectl,
        ctx.executable._script,
        ctx.file.resource,
    ]
    return [DefaultInfo(
        executable = executable,
        runfiles = ctx.runfiles(files = runfiles),
    )]

attrs = {
    "namespace": attr.string(
        mandatory = True,
    ),
    "resource": attr.label(
        mandatory = True,
        allow_single_file = True,
    ),
    "_kubectl": attr.label(
        allow_single_file = True,
        cfg = "host",
        default = "@kubectl//:kubectl",
        executable = True,
    ),
}

apply = rule(
    implementation = _kubectl_impl,
    attrs = dict({
        "_script": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "//rules/kubectl:apply.sh",
            executable = True,
        ),
    }, **attrs),
    executable = True,
)

delete = rule(
    implementation = _kubectl_impl,
    attrs = dict({
        "_script": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "//rules/kubectl:delete.sh",
            executable = True,
        ),
    }, **attrs),
    executable = True,
)

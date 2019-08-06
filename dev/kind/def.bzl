def _kind_impl(ctx):
    executable = ctx.actions.declare_file(ctx.attr.name)
    contents = """
        set -o errexit
        export KIND="{kind}"
        export CLUSTER_NAME="{cluster_name}"
        export KUBECTL="{kubectl}"
        "{script}"
    """.format(
        kind = ctx.executable._kind.path,
        cluster_name = ctx.attr.cluster_name,
        kubectl = ctx.executable._kubectl.path,
        script = ctx.executable._script.path,
    )
    ctx.actions.write(executable, contents, is_executable = True)
    runfiles = [
        ctx.executable._kind,
        ctx.executable._kubectl,
        ctx.executable._script,
    ]
    return [DefaultInfo(
        executable = executable,
        runfiles = ctx.runfiles(files = runfiles),
    )]

attrs = {
    "cluster_name": attr.string(
        mandatory = True,
    ),
    "_kind": attr.label(
        allow_single_file = True,
        cfg = "host",
        default = "@kind//:kind",
        executable = True,
    ),
    "_kubectl": attr.label(
        allow_single_file = True,
        cfg = "host",
        default = "@kubectl//:kubectl",
        executable = True,
    ),
}

kind_start_binary = rule(
    implementation = _kind_impl,
    attrs = dict({
        "_script": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "//dev/kind:start.sh",
            executable = True,
        )
    }, **attrs),
    executable = True,
)

kind_delete_binary = rule(
    implementation = _kind_impl,
    attrs = dict({
        "_script": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "//dev/kind:delete.sh",
            executable = True,
        )
    }, **attrs),
    executable = True,
)

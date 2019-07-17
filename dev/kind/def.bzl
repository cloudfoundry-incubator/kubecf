def _kind_impl(ctx):
    executable = ctx.actions.declare_file(ctx.attr.name)
    contents = """
        set -o errexit
        export KIND="{kind}"
        export CLUSTER_NAME="{cluster_name}"
        export KUBECTL="{kubectl}"
        export HELM_INIT="{helm_init}"
        "{script}"
    """.format(
        kind = ctx.executable._kind.path,
        cluster_name = ctx.attr.cluster_name,
        kubectl = ctx.executable._kubectl.path,
        helm_init = ctx.executable._helm_init.short_path,
        script = ctx.executable._script.path,
    )
    ctx.actions.write(executable, contents, is_executable = True)
    runfiles = [
        ctx.executable._kind,
        ctx.executable._kubectl,
        ctx.executable._helm_init,
        ctx.executable._script,
    ]
    helm_init_runfiles = ctx.attr._helm_init[DefaultInfo].data_runfiles
    return [DefaultInfo(
        executable = executable,
        runfiles = ctx.runfiles(files = runfiles).merge(helm_init_runfiles),
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
    "_helm_init": attr.label(
        allow_single_file = True,
        cfg = "host",
        default = "//rules/helm:init",
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

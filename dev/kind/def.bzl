load("@bazel_skylib//lib:paths.bzl", "paths")

def _kind_impl(ctx):
    metrics_server_dir = None
    for f in ctx.files._metrics_server:
        dir = paths.dirname(f.path)
        if metrics_server_dir == None:
            metrics_server_dir = dir
        else:
            if dir != metrics_server_dir:
                print("{} != {}".format(dir, metrics_server_dir))
                fail("multiple directories are not supported for the metrics-server")

    executable = ctx.actions.declare_file(ctx.attr.name)
    contents = """
        set -o errexit
        export KIND="{kind}"
        export CLUSTER_NAME="{cluster_name}"
        export KUBECTL="{kubectl}"
        export METRICS_SERVER="{metrics_server}"
        "{script}"
    """.format(
        kind = ctx.executable._kind.path,
        cluster_name = ctx.attr.cluster_name,
        kubectl = ctx.executable._kubectl.path,
        metrics_server = metrics_server_dir,
        script = ctx.executable._script.path,
    )
    ctx.actions.write(executable, contents, is_executable = True)
    runfiles = [
        ctx.executable._kind,
        ctx.executable._kubectl,
        ctx.executable._script,
    ] + ctx.files._metrics_server
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
    "_metrics_server": attr.label(
        default = "@com_github_kubernetes_incubator_metrics_server//:deploy",
        allow_files = True,
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

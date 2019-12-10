load("@bazel_skylib//lib:paths.bzl", "paths")
load("//:def.bzl", "project")

def _start_drone_runner_impl(ctx):
    template_name = paths.basename(ctx.file._script_template.short_path)
    script = ctx.actions.declare_file("rendered_{}".format(template_name))

    ctx.actions.expand_template(
        template = ctx.file._script_template,
        output = script,
        substitutions = {
            "{rpc_host}": ctx.attr._rpc_host,
            "{rpc_proto}": ctx.attr._rpc_proto,
            "{runner_capacity}": ctx.attr._runner_capacity,
            "{runner_image_version}": ctx.attr._runner_image_version,
            "{runner_image_sha256}": ctx.attr._runner_image_sha256,
        },
        is_executable = True,
    )

    runfiles = []

    return [DefaultInfo(
        executable = script,
        runfiles = ctx.runfiles(files = runfiles),
    )]

start_drone_runner = rule(
    implementation = _start_drone_runner_impl,
    attrs = {
        "_rpc_host": attr.string(
            default = project.drone.runner.rpc_host,
        ),
        "_rpc_proto": attr.string(
            default = project.drone.runner.rpc_proto,
        ),
        "_runner_capacity": attr.string(
            default = str(project.drone.runner.capacity),
        ),
        "_runner_image_version": attr.string(
            default = str(project.drone.runner.image.version),
        ),
        "_runner_image_sha256": attr.string(
            default = project.drone.runner.image.sha256,
        ),
        "_script_template": attr.label(
            allow_single_file = True,
            default = "//.drone/deploy/runner:start.sh",
        ),
    },
    executable = True,
)

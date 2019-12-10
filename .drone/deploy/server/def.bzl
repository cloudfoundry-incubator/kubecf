load("@bazel_skylib//lib:paths.bzl", "paths")
load("//:def.bzl", "project")

def _deploy_drone_server_impl(ctx):
    template_name = paths.basename(ctx.file._script_template.short_path)
    script = ctx.actions.declare_file("rendered_{}".format(template_name))

    ctx.actions.expand_template(
        template = ctx.file._script_template,
        output = script,
        substitutions = {
            "{dockerfile_path}": ctx.file._dockerfile.short_path,
            "{app_name}": ctx.attr.app_name,
            "{drone_image_version}": ctx.attr._drone_image_version,
            "{drone_image_sha256}": ctx.attr._drone_image_sha256,
        },
        is_executable = True,
    )

    runfiles = [
        ctx.file._dockerfile,
    ]

    return [DefaultInfo(
        executable = script,
        runfiles = ctx.runfiles(files = runfiles),
    )]

deploy_drone_server = rule(
    implementation = _deploy_drone_server_impl,
    attrs = {
        "app_name": attr.string(
            default = project.drone.server.app_name,
        ),
        "_drone_image_version": attr.string(
            default = str(project.drone.server.image.version),
        ),
        "_drone_image_sha256": attr.string(
            default = project.drone.server.image.sha256,
        ),
        "_dockerfile": attr.label(
            allow_single_file = True,
            default = "//.drone/deploy/server:image/Dockerfile.web",
        ),
        "_script_template": attr.label(
            allow_single_file = True,
            default = "//.drone/deploy/server:deploy.sh",
        ),
    },
    executable = True,
)

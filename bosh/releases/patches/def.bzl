def _patch_impl(ctx):
    output_filename = "{}.yaml".format(ctx.attr.name)
    output_yaml = ctx.actions.declare_file(output_filename)
    outputs = [output_yaml]
    ctx.actions.run(
        inputs = [ctx.file.patch],
        outputs = outputs,
        progress_message = "Generating patch ops-file {}".format(output_filename),
        executable = ctx.executable._generator,
        arguments = [
            "--job={}".format(ctx.attr.job),
            "--instance-group={}".format(ctx.attr.instance_group),
            "--target={}".format(ctx.attr.target),
            "--patch={}".format(ctx.file.patch.path),
            "--output={}".format(output_yaml.path),
        ],
    )
    return [DefaultInfo(files = depset(outputs))]

patch = rule(
    implementation = _patch_impl,
    attrs = {
        "job": attr.string(
            mandatory = True,
        ),
        "instance_group": attr.string(
            mandatory = True,
        ),
        "target": attr.string(
            mandatory = True,
        ),
        "patch": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "_generator": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "//bosh/releases/patches/generator",
            executable = True,
        ),
    },
)

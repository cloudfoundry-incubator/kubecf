load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_tools//tools/build_defs/pkg:pkg.bzl", "pkg_tar")

def _pre_render_script_ops_impl(ctx):
    output_filename = "{}.yaml".format(ctx.attr.name)
    output_yaml = ctx.actions.declare_file(output_filename)
    outputs = [output_yaml]
    ctx.actions.run(
        inputs = [ctx.file.script],
        outputs = outputs,
        progress_message = "Generating pre_render_script ops-file {}".format(output_filename),
        executable = ctx.executable._generator,
        env = {
            "INSTANCE_GROUP": ctx.attr.instance_group,
            "JOB": ctx.attr.job,
            "PRE_RENDER_SCRIPT": ctx.file.script.path,
            "OUTPUT": output_yaml.path,
        },
    )
    return [DefaultInfo(files = depset(outputs))]

pre_render_script_ops = rule(
    implementation = _pre_render_script_ops_impl,
    attrs = {
        "instance_group": attr.string(
            mandatory = True,
        ),
        "job": attr.string(
            mandatory = True,
        ),
        "script": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "_generator": attr.label(
            allow_single_file = True,
            cfg = "host",
            default = "//bosh/releases/generators/pre_render_scripts:generator.sh",
            executable = True,
        ),
    },
)

def generate_pre_render_script_ops(name, srcs):
    scripts = [_map_pre_render_script(src) for src in srcs]
    for script in scripts:
        pre_render_script_ops(
            name = script.ops_file_target_name,
            instance_group = script.instance_group,
            job = script.job,
            script = script.src_target,
        )

    pkg_tar(
        name = name,
        package_dir = "assets/operations/pre_render_scripts",
        srcs = [":{}".format(script.ops_file_target_name) for script in scripts],
    )

def _map_pre_render_script(src):
    job = paths.basename(paths.dirname(src))
    instance_group = paths.basename(paths.dirname(paths.dirname(src)))
    src_target = ":{}".format(src)
    src_basename = paths.basename(src)
    return struct(
        job = job,
        instance_group = instance_group,
        src_target = src_target,
        ops_file_target_name = "{}_{}_{}".format(instance_group, job, src_basename.replace(".", "_"))
    )

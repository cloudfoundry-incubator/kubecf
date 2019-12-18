def _external_binary_impl(ctx):
    info = None
    if ctx.os.name == 'mac os x':
        info = ctx.attr.darwin
        _validade_platform_info("darwin", info)
    elif ctx.os.name == 'linux':
        info = ctx.attr.linux
        _validade_platform_info("linux", info)
    elif ctx.os.name == 'windows':
        info = ctx.attr.windows
        _validade_platform_info("windows", info)
    else:
        fail("Unsupported operating system: {}".format(ctx.os.name))

    url = info.get("url")
    args = {
        "url": url,
        "sha256": info.get("sha256", ""),
    }
    if any([url.endswith(suffix) for suffix in [".zip", ".tar.gz", ".tgz", ".tar.bz2", ".tar.xz"]]):
        ctx.download_and_extract(output="{name}/{name}_out".format(name = ctx.attr.name), **args)
    else:
        args["executable"] = True
        ctx.download(output="{name}/{name}".format(name = ctx.attr.name), **args)

    build_contents = """
    package(default_visibility = ["//visibility:public"])

    load("@bazel_skylib//rules:copy_file.bzl", "copy_file")

    filegroup(
        name = "{name}_filegroup",
        srcs = glob([
            "**/{name}",
            "**/{name}.exe",
        ]),
    )

    copy_file(
        name = "binary",
        src = ":{name}_filegroup",
        out = "{name}",
        is_executable = True,
    )
    """.format(name = ctx.attr.name)
    build_contents = '\n'.join([x.lstrip(' ') for x in build_contents.splitlines()])
    ctx.file("BUILD.bazel".format(name = ctx.attr.name), build_contents)

_external_binary = repository_rule(
    implementation = _external_binary_impl,
    attrs = {
        "darwin": attr.string_dict(),
        "linux": attr.string_dict(),
        "windows": attr.string_dict(),
    },
)

def external_binary(name, platforms):
    _external_binary(
        name = name,
        darwin = platforms.get("darwin"),
        linux = platforms.get("linux"),
        windows = platforms.get("windows"),
    )

def _validade_platform_info(platform, info):
    if not "url" in info:
        fail("missing attr 'url' in '{}'".format(platform))

def _binary_location_impl(ctx):
    script = ctx.actions.declare_file(ctx.attr.name)
    contents = "echo \"$(realpath $(pwd)/{})\"".format(ctx.executable.binary.short_path)
    ctx.actions.write(script, contents, is_executable = True)
    return [DefaultInfo(
        executable = script,
        runfiles = ctx.runfiles(files = [ctx.executable.binary]),
    )]

binary_location = rule(
    implementation = _binary_location_impl,
    attrs = {
        "binary": attr.label(
            allow_single_file = True,
            cfg = "host",
            executable = True,
        ),
    },
    executable = True,
)

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

    args = {
        "url": info.get("url"),
        "sha256": info.get("sha256", ""),
        "output": "executable/executable",
    }
    if info.get("is_compressed", False):
        ctx.download_and_extract(**args)
    else:
        args["executable"] = True
        ctx.download(**args)

    build_contents = 'package(default_visibility = ["//visibility:public"])\n'
    build_contents += 'exports_files(["executable"])\n'
    ctx.file("executable/BUILD.bazel", build_contents)

external_binary = repository_rule(
    implementation = _external_binary_impl,
    attrs = {
        "darwin": attr.string_dict(),
        "linux": attr.string_dict(),
        "windows": attr.string_dict(),
    },
)

def _validade_platform_info(platform, info):
    if not "url" in info:
        fail("missing attr 'url' in '{}'".format(platform))

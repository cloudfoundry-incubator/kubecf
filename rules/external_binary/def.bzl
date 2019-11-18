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
        "output": "{name}/{name}".format(name = ctx.attr.name),
    }
    if url.endswith(".zip") or url.endswith(".tar.gz") or url.endswith(".tgz"):
        ctx.download_and_extract(**args)
        flatten = [
            "sh", "-c",
            """
            set -o errexit -o pipefail
            mkdir '{name}_tmp'
            find '{name}' -mindepth 2 -type f -print0 \
                | xargs -0 -L50 mv --target-directory '{name}_tmp'
            rm -rf '{name}'
            mv '{name}_tmp' '{name}'
            """.format(
                name = ctx.attr.name,
            )
        ]
        res = ctx.execute(flatten)
        if res.stdout != "":
            print("STDOUT:")
            print(res.stdout)
        if res.stderr != "":
            print("STDERR:")
            print(res.stderr)
    else:
        args["executable"] = True
        ctx.download(**args)

    build_contents = 'package(default_visibility = ["//visibility:public"])\n'
    build_contents += 'exports_files(glob(["**/*"]))\n'
    ctx.file("{name}/BUILD.bazel".format(name = ctx.attr.name), build_contents)

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
    contents = "echo \"$(pwd)/{}\"".format(ctx.executable.binary.path)
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

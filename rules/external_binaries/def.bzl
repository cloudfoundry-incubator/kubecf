"""
This module contains the implementation to pull in external binaries.
"""

def _external_binary_impl(ctx):
    os = ctx.os.name
    if os == "mac os x":
        os = "darwin"

    url = ctx.attr.url[os].format(version = ctx.attr.version, platform = os)
    args = {
        "url": url,
        "sha256": ctx.attr.sha256[os],
    }

    if ctx.attr.strip_prefix.get(os, "") != "":
        args["stripPrefix"] = ctx.attr.strip_prefix[os]

    if any([url.endswith(suffix) for suffix in [".zip", ".tar.gz", ".tgz", ".tar.bz2", ".tar.xz"]]):
        ctx.download_and_extract(output = ".", **args)
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
            out = ".binary",
            is_executable = True,
        )

        exports_files(glob(["**/*"]))
        """.format(name = ctx.attr.name)
    else:
        args["executable"] = True
        ctx.download(output = "{name}".format(name = ctx.attr.name), **args)
        build_contents = """
        package(default_visibility = ["//visibility:public"])

        load("@bazel_skylib//rules:copy_file.bzl", "copy_file")

        exports_files(["{name}"])

        copy_file(
            name = "binary",
            src = ":{name}",
            out = ".binary",
            is_executable = True,
        )
        """.format(name = ctx.attr.name)

    build_contents = '\n'.join([x.lstrip(' ') for x in build_contents.splitlines()])
    ctx.file("BUILD.bazel", build_contents)

_external_binary = repository_rule(
    implementation = _external_binary_impl,
    attrs = {
        "sha256": attr.string_dict(
            allow_empty = False,
            doc = "Checksum of the binaries, keyed by os name",
        ),
        "url": attr.string_dict(
            allow_empty = False,
            doc = "URL to download the binary from, keyed by platform; {version} will be replaced",
        ),
        "version": attr.string(
            doc = "Version of the binary",
            mandatory = False,
        ),
        "strip_prefix": attr.string_dict(
            allow_empty = True,
            doc = "Directory prefixex to strip from the extracted files",
        ),
    },
)

def external_binary(name, config):
    _external_binary(
        name = name,
        **config
    )

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

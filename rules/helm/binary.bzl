load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _helm_binary_impl(ctx):
    os_name = ctx.os.name
    if os_name == 'linux':
        helm_bin = ctx.path(ctx.attr._helm_linux)
    elif os_name == 'mac os x':
        helm_bin = ctx.path(ctx.attr._helm_darwin)
    elif os_name == 'windows':
        helm_bin = ctx.path(ctx.attr._helm_windows)
    else:
        fail("Unsupported operating system: {}".format(os_name))
    # Symlinks the helm_bin to helm so it becomes OS agnostic to call the binary.
    ctx.symlink(helm_bin, "helm")
    ctx.file(
        "BUILD",
        """
package(default_visibility = ["//visibility:public"])
exports_files(["helm"])
""",
    )

_helm_binary = repository_rule(
    implementation = _helm_binary_impl,
    attrs = {
        "_helm_linux": attr.label(
            default = Label("@helm_linux_amd64//:helm"),
            allow_single_file = True,
        ),
        "_helm_darwin": attr.label(
            default = Label("@helm_darwin_amd64//:helm"),
            allow_single_file = True,
        ),
        "_helm_windows": attr.label(
            default = Label("@helm_windows_amd64//:helm"),
            allow_single_file = True,
        ),
    },
)

def helm_binary(name, version, platforms):
    for p in platforms:
        http_archive(
            name =  "helm_{}_amd64".format(p["platform"]),
            url = "{base_url}/helm-v{version}-{platform}-amd64.tar.gz".format(
                base_url = "https://get.helm.sh",
                version = version,
                platform = p["platform"],
            ),
            strip_prefix = "{platform}-amd64".format(platform = p["platform"]),
            build_file_content = """
package(default_visibility = ["//visibility:public"])
exports_files(["**/*"])
""",
            sha256 = p["sha256"],
        )
    _helm_binary(
        name = name,
    )

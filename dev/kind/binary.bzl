load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

def _kind_binary_impl(ctx):
    os_name = ctx.os.name
    if os_name == 'linux':
        kind_bin = ctx.path(ctx.attr._kind_linux)
    elif os_name == 'mac os x':
        kind_bin = ctx.path(ctx.attr._kind_darwin)
    elif os_name == 'windows':
        kind_bin = ctx.path(ctx.attr._kind_windows)
    else:
        fail("Unsupported operating system: {}".format(os_name))
    # Symlinks the kind_bin to kind so it becomes OS agnostic to call the binary.
    ctx.symlink(kind_bin, "kind")
    ctx.file(
        "BUILD",
        """
package(default_visibility = ["//visibility:public"])
exports_files(["kind"])
""",
    )

_kind_binary = repository_rule(
    implementation = _kind_binary_impl,
    attrs = {
        "_kind_linux": attr.label(
            default = Label("@kind_linux_amd64//file:downloaded"),
            allow_single_file = True,
        ),
        "_kind_darwin": attr.label(
            default = Label("@kind_darwin_amd64//file:downloaded"),
            allow_single_file = True,
        ),
        "_kind_windows": attr.label(
            default = Label("@kind_windows_amd64//file:downloaded"),
            allow_single_file = True,
        ),
    },
)

def kind_binary(name, version, platforms):
    for p in platforms:
        http_file(
            name =  "kind_{}_amd64".format(p["platform"]),
            urls = ["{base_url}/v{version}/kind-{platform}-amd64".format(
                base_url = "https://github.com/kubernetes-sigs/kind/releases/download",
                version = version,
                platform = p["platform"],
            )],
            sha256 = p["sha256"],
            executable = True,
        )
    _kind_binary(
        name = name,
    )

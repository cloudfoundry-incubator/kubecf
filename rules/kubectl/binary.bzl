load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

def _kubectl_binary_impl(ctx):
    os_name = ctx.os.name
    if os_name == 'linux':
        kubectl_bin = ctx.path(ctx.attr._kubectl_linux)
    elif os_name == 'mac os x':
        kubectl_bin = ctx.path(ctx.attr._kubectl_darwin)
    elif os_name == 'windows':
        kubectl_bin = ctx.path(ctx.attr._kubectl_windows)
    else:
        fail("Unsupported operating system: {}".format(os_name))
    # Symlinks the kubectl_bin to kubectl so it becomes OS agnostic to call the binary.
    ctx.symlink(kubectl_bin, "kubectl")
    ctx.file(
        "BUILD",
        """
package(default_visibility = ["//visibility:public"])
exports_files(["kubectl"])
""",
    )

_kubectl_binary = repository_rule(
    implementation = _kubectl_binary_impl,
    attrs = {
        "_kubectl_linux": attr.label(
            default = Label("@kubectl_linux_amd64//file:downloaded"),
            allow_single_file = True,
        ),
        "_kubectl_darwin": attr.label(
            default = Label("@kubectl_darwin_amd64//file:downloaded"),
            allow_single_file = True,
        ),
        "_kubectl_windows": attr.label(
            default = Label("@kubectl_windows_amd64//file:downloaded"),
            allow_single_file = True,
        ),
    },
)

def kubectl_binary(name, version, platforms):
    for p in platforms:
        http_file(
            name =  "kubectl_{}_amd64".format(p["platform"]),
            urls = ["{base_url}/v{version}/bin/{platform}/amd64/kubectl{extension}".format(
                base_url = "https://storage.googleapis.com/kubernetes-release/release",
                version = version,
                platform = p["platform"],
                extension = ".exe" if p["platform"] == "windows" else "",
            )],
            sha256 = p["sha256"],
            executable = True,
        )
    _kubectl_binary(
        name = name,
    )

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

def _minikube_binary_impl(ctx):
    os_name = ctx.os.name
    if os_name == 'linux':
        minikube_bin = ctx.path(ctx.attr._minikube_linux)
    elif os_name == 'mac os x':
        minikube_bin = ctx.path(ctx.attr._minikube_darwin)
    elif os_name == 'windows':
        minikube_bin = ctx.path(ctx.attr._minikube_windows)
    else:
        fail("Unsupported operating system: {}".format(os_name))
    # Symlinks the minikube_bin to minikube so it becomes OS agnostic to call the binary.
    ctx.symlink(minikube_bin, "minikube")
    ctx.file(
        "BUILD",
        """
package(default_visibility = ["//visibility:public"])
exports_files(["minikube"])
""",
    )

_minikube_binary = repository_rule(
    implementation = _minikube_binary_impl,
    attrs = {
        "_minikube_linux": attr.label(
            default = Label("@minikube_linux_amd64//file:downloaded"),
            allow_single_file = True,
        ),
        "_minikube_darwin": attr.label(
            default = Label("@minikube_darwin_amd64//file:downloaded"),
            allow_single_file = True,
        ),
        "_minikube_windows": attr.label(
            default = Label("@minikube_windows_amd64//file:downloaded"),
            allow_single_file = True,
        ),
    },
)

def minikube_binary(name, version, platforms):
    for p in platforms:
        http_file(
            name =  "minikube_{}_amd64".format(p["platform"]),
            urls = ["{base_url}/v{version}/minikube-{platform}-amd64{extension}".format(
                base_url = "https://storage.googleapis.com/minikube/releases",
                version = version,
                platform = p["platform"],
                extension = ".exe" if p["platform"] == "windows" else "",
            )],
            sha256 = p["sha256"],
            executable = True,
        )
    _minikube_binary(
        name = name,
    )

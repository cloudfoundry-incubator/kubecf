workspace(name = "scf")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//rules/helm:binary.bzl", "helm_binary")

http_archive(
    name = "cf_deployment",
    build_file_content = """
package(default_visibility = ["//visibility:public"])
filegroup(
    name = "cf_deployment",
    srcs = ["cf-deployment.yml"],
)
""",
    sha256 = "3539012bba59787fdc41a68315ebea991ce842404ef029cf1281fc03a1081c2b",
    strip_prefix = "cf-deployment-7.11.0",
    url = "https://github.com/cloudfoundry/cf-deployment/archive/v7.11.0.tar.gz",
)

helm_binary(
    name = "helm",
    version = "v2.14.1",
    platforms = [
        {
            "platform": "linux",
            "sha256": "804f745e6884435ef1343f4de8940f9db64f935cd9a55ad3d9153d064b7f5896",
        },
        {
            "platform": "darwin",
            "sha256": "392ec847ecc5870a48a39cb0b8d13c8aa72aaf4365e0315c4d7a2553019a451c",
        },
        {
            "platform": "windows",
            "sha256": "604780d3fabeb27e7ab7a30c6e29ce64bcd2203501ea35e5231c97965b0255a0",
        },
    ]
)

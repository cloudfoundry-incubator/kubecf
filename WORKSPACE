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
    sha256 = "289f6c5a116eef4b16b228d07d55517dc20f76199c1476036fc0ade5a08a3e1b",
    strip_prefix = "cf-deployment-8.0.0",
    url = "https://github.com/cloudfoundry/cf-deployment/archive/v8.0.0.tar.gz",
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
    ],
)

skylib_version = "0.8.0"
http_archive(
    name = "bazel_skylib",
    url = "https://github.com/bazelbuild/bazel-skylib/releases/download/{}/bazel-skylib.{}.tar.gz".format(skylib_version, skylib_version),
    sha256 = "2ef429f5d7ce7111263289644d233707dba35e39696377ebab8b0bc701f7818e",
)

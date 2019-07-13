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
    ],
)

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "io_bazel_rules_go",
    urls = [
        "https://storage.googleapis.com/bazel-mirror/github.com/bazelbuild/rules_go/releases/download/0.18.7/rules_go-0.18.7.tar.gz",
        "https://github.com/bazelbuild/rules_go/releases/download/0.18.7/rules_go-0.18.7.tar.gz",
    ],
    sha256 = "45409e6c4f748baa9e05f8f6ab6efaa05739aa064e3ab94e5a1a09849c51806a",
)

http_archive(
    name = "bazel_gazelle",
    urls = ["https://github.com/bazelbuild/bazel-gazelle/releases/download/0.17.0/bazel-gazelle-0.17.0.tar.gz"],
    sha256 = "3c681998538231a2d24d0c07ed5a7658cb72bfb5fd4bf9911157c0e9ac6a2687",
)

load("@io_bazel_rules_go//go:deps.bzl", "go_rules_dependencies", "go_register_toolchains")

go_rules_dependencies()

go_register_toolchains()

load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies", "go_repository")

gazelle_dependencies()

go_repository(
    name = "com_github_davecgh_go_spew",
    build_external = "vendored",
    build_file_proto_mode = "disable_global",
    importpath = "github.com/davecgh/go-spew",
    tag = "v1.1.1",
)

go_repository(
    name = "com_github_kr_pretty",
    build_external = "vendored",
    build_file_proto_mode = "disable_global",
    importpath = "github.com/kr/pretty",
    tag = "v0.1.0",
)

go_repository(
    name = "com_github_kr_pty",
    build_external = "vendored",
    build_file_proto_mode = "disable_global",
    importpath = "github.com/kr/pty",
    tag = "v1.1.1",
)

go_repository(
    name = "com_github_kr_text",
    build_external = "vendored",
    build_file_proto_mode = "disable_global",
    importpath = "github.com/kr/text",
    tag = "v0.1.0",
)

go_repository(
    name = "com_github_pmezard_go_difflib",
    build_external = "vendored",
    build_file_proto_mode = "disable_global",
    importpath = "github.com/pmezard/go-difflib",
    tag = "v1.0.0",
)

go_repository(
    name = "com_github_stretchr_objx",
    build_external = "vendored",
    build_file_proto_mode = "disable_global",
    importpath = "github.com/stretchr/objx",
    tag = "v0.1.0",
)

go_repository(
    name = "com_github_stretchr_testify",
    build_external = "vendored",
    build_file_proto_mode = "disable_global",
    importpath = "github.com/stretchr/testify",
    tag = "v1.3.0",
)

go_repository(
    name = "in_gopkg_check_v1",
    build_external = "vendored",
    build_file_proto_mode = "disable_global",
    commit = "788fd7840127",
    importpath = "gopkg.in/check.v1",
)

go_repository(
    name = "in_gopkg_yaml_v2",
    build_external = "vendored",
    build_file_proto_mode = "disable_global",
    importpath = "gopkg.in/yaml.v2",
    tag = "v2.2.2",
)

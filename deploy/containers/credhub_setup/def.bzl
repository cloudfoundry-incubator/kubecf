"""
Sub-workspace-wide definitions for credhub-setup; see main.go for info.
"""
project = struct(
    bazel_libs = {
        "bazel_gazelle": struct(
            urls = [
                "https://storage.googleapis.com/bazel-mirror/github.com/bazelbuild/bazel-gazelle/releases/download/v{version}/bazel-gazelle-v{version}.tar.gz",
                "https://github.com/bazelbuild/bazel-gazelle/releases/download/v{version}/bazel-gazelle-v{version}.tar.gz",
            ],
            version = "0.19.1",
            sha256 = "86c6d481b3f7aedc1d60c1c211c6f76da282ae197c3b3160f54bd3a8f847896f",
        ),
        "io_bazel_rules_docker": struct(
            urls = [
                "https://github.com/bazelbuild/rules_docker/archive/v{version}.tar.gz",
            ],
            version = "0.13.0",
            sha256 = "df13123c44b4a4ff2c2f337b906763879d94871d16411bf82dcfeba892b58607",
            strip_prefix = "rules_docker-{version}",
        ),
        "io_bazel_rules_go": struct(
            urls = [
                "https://storage.googleapis.com/bazel-mirror/github.com/bazelbuild/rules_go/releases/download/v{version}/rules_go-v{version}.tar.gz",
                "https://github.com/bazelbuild/rules_go/releases/download/v{version}/rules_go-v{version}.tar.gz",
            ],
            version = "0.21.0",
            sha256 = "b27e55d2dcc9e6020e17614ae6e0374818a3e3ce6f2024036e688ada24110444",
        ),
        "rules_gomplate": struct(
            urls = ["https://github.com/codelogia/rules_gomplate/archive/{version}.tar.gz"],
            version = "3ab8ff7a25d9c13c8a9d2c5a122241c745a92570",
            sha256 = "5f2c173824020dea6923e0fa20d13df4a1d4cbe264acc009efa41f8a1a50e7d4",
            strip_prefix = "rules_gomplate-{version}",
        ),
    },
    external_binaries = {
        "jq": struct(
            sha256 = {
                "darwin":  "5c0a0a3ea600f302ee458b30317425dd9632d1ad8882259fcaf4e9b868b2b1ef",
                "linux":   "af986793a515d500ab2d35f8d2aecd656e764504b789b66d7e1a0b727a124c44",
                "windows": "a51d36968dcbdeabb3142c6f5cf9b401a65dc3a095f3144bd0c118d5bb192753",
            },
            url = {
                "darwin":  "https://github.com/stedolan/jq/releases/download/jq-{version}/jq-osx-amd64",
                "linux":   "https://github.com/stedolan/jq/releases/download/jq-{version}/jq-linux64",
                "windows": "https://github.com/stedolan/jq/releases/download/jq-{version}/jq-win64.exe",
            },
            version = "1.6",
        ),
    },
)

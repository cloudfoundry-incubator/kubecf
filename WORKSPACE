workspace(name = "kubecf")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")

http_archive(
    name = "bazel_skylib",
    urls = [
        "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.0.2/bazel-skylib-1.0.2.tar.gz",
        "https://github.com/bazelbuild/bazel-skylib/releases/download/1.0.2/bazel-skylib-1.0.2.tar.gz",
    ],
    sha256 = "97e70364e9249702246c0e9444bccdc4b847bed1eb03c5a3ece4f83dfe6abc44",
)

load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

bazel_skylib_workspace()

local_repository(
    name = "workspace",
    path = "rules/workspace",
)

load("@workspace//:def.bzl", "workspace_dependencies", "yaml_loader")

workspace_dependencies()

local_repository(
    name = "external_binaries",
    path = "rules/external_binaries",
)

yaml_loader(
    name = "dependencies",
    src = "@//:dependencies.yaml",
    out = "def.bzl",
)

load("@dependencies//:def.bzl", "bazel_libs", "binaries", "external_files")

[http_archive(
    name = name,
    sha256 = config["sha256"],
    urls = [config["url"].format(version = config["version"])],
    strip_prefix = config.get("strip_prefix", "").format(version = config["version"]),
    build_file_content = config.get("build_file_content", None),
) for name, config in bazel_libs.items()]

[http_file(
    name = name,
    urls = [config["url"].format(version = config.get("version", ""))],
    sha256 = config["sha256"],
) for name, config in external_files.items()]

load("@external_binaries//:def.bzl", "external_binary")

[external_binary(
    name = name,
    config = config,
) for name, config in binaries.items()]

load("@rules_python//python:pip.bzl", "pip_repositories", "pip3_import")

pip_repositories()

pip3_import(
    name = "yamllint",
    requirements = "//dev/linters/yamllint:requirements.txt",
)

load("@yamllint//:requirements.bzl", "pip_install")

pip_install()

load("@rules_gomplate//:repositories.bzl", "gomplate_repositories")

gomplate_repositories()

load("//rules/helm:def.bzl", helm_dependencies = "dependencies")

helm_dependencies(
    name = "kubecf_helm_dependencies",
    chart_yaml = "//deploy/helm/kubecf:Chart.yaml",
    requirements = "//deploy/helm/kubecf:requirements.yaml",
    requirements_lock = "//deploy/helm/kubecf:requirements.lock",
)

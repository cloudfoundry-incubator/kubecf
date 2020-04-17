workspace(name = "kubecf")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")

local_repository(
    name = "workspace_status",
    path = "rules/workspace_status",
)

load(":def.bzl", "project")

[http_archive(
    name = name,
    sha256 = config.sha256,
    urls = [u.format(version = config.version) for u in config.urls],
    strip_prefix = getattr(config, "strip_prefix", "").format(version = config.version),
    build_file_content = getattr(config, "build_file_content", None),
) for name, config in project.bazel_libs.items()]

[http_file(
    name = name,
    urls = [u.format(version = getattr(config, "version", "")) for u in config.urls],
    sha256 = config.sha256,
) for name, config in project.external_files.items()]

load("@suse_rules_binaries//:def.bzl", "binary")

[binary(
    name = name,
    config = config,
) for name, config in project.external_binaries.items()]

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

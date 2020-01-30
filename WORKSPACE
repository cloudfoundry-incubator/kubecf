workspace(name = "kubecf")

load(":def.bzl", "project")

local_repository(
    name = "workspace_status",
    path = "rules/workspace_status",
)

local_repository(
    name = "external_binaries",
    path = "rules/external_binaries",
)

load("@external_binaries//:def.bzl", "external_binary")

[external_binary(
    name = name,
    config = config,
) for name, config in project.external_binaries.items()]

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")

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

load("@io_bazel_rules_docker//repositories:repositories.bzl", container_repositories = "repositories")

container_repositories()

load("@io_bazel_rules_go//go:deps.bzl", "go_rules_dependencies", "go_register_toolchains")

go_rules_dependencies()

go_register_toolchains()

# gazelle:repo bazel_gazelle
# gazelle:repository_macro deploy/containers/credhub_setup/repositories.bzl%go_repositories
load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")

gazelle_dependencies()

load("@io_bazel_rules_docker//go:image.bzl", _go_image_repos = "repositories")

_go_image_repos()

local_repository(
    name = "credhub_setup",
    path = "deploy/containers/credhub_setup",
)

load("@credhub_setup//:repositories.bzl", credhub_go_repositories = "go_repositories")

credhub_go_repositories()

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

load("@rules_python//python:pip.bzl", "pip_repositories", "pip3_import")

pip_repositories()

pip3_import(
    name = "yamllint",
    requirements = "//dev/linters/yamllint:requirements.txt",
)

load("@yamllint//:requirements.bzl", "pip_install")

pip_install()

http_file(
    name = "cf_operator",
    sha256 = project.cf_operator.chart.sha256,
    urls = [project.cf_operator.chart.url],
)

http_file(
    name = "local_path_provisioner",
    sha256 = project.local_path_provisioner.sha256,
    urls = [project.local_path_provisioner.url],
)

http_file(
    name = "kube_dashboard",
    sha256 = project.kube_dashboard.sha256,
    urls = [project.kube_dashboard.url],
)

http_file(
    name = "weave_container_network_plugin",
    sha256 = project.weave_container_network_plugin.sha256,
    urls = [project.weave_container_network_plugin.url],
)

http_file(
    name = "mysql_chart",
    sha256 = project.mysql_chart.sha256,
    urls = ["https://kubernetes-charts.storage.googleapis.com/mysql-{}.tgz".format(project.mysql_chart.version)],
)

http_archive(
    name = "rules_gomplate",
    sha256 = project.rules_gomplate.sha256,
    strip_prefix = "rules_gomplate-{commit}".format(commit = project.rules_gomplate.commit),
    url = "https://github.com/codelogia/rules_gomplate/archive/{commit}.tar.gz".format(commit = project.rules_gomplate.commit),
)

load("@rules_gomplate//:repositories.bzl", "gomplate_repositories")

gomplate_repositories()

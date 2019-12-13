workspace(name = "kubecf")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")
load("//dev/minikube:binary.bzl", "minikube_binary")
load("//rules/external_binary:def.bzl", "external_binary")
load(":def.bzl", "project")

[external_binary(
    name = name,
    platforms = getattr(project, name).platforms,
) for name in [
    "helm",
    "jq",
    "k3s",
    "kind",
    "kubectl",
    "shellcheck",
    "yaml2json",
]]

# Declare all binaries on the docker compressed release.
[external_binary(
    name = name,
    platforms = project.docker.platforms,
) for name in [
    "containerd",
    "containerd-shim",
    "ctr",
    "docker",
    "dockerd",
    "docker-init",
    "docker-proxy",
    "runc",
]]

minikube_binary(
    name = "minikube",
    platforms = project.minikube.platforms,
    version = project.minikube.version,
)

http_archive(
    name = "rules_python",
    sha256 = project.rules_python.sha256,
    strip_prefix = "rules_python-{commit}".format(commit = project.rules_python.commit),
    url = "https://github.com/bazelbuild/rules_python/archive/{commit}.tar.gz".format(commit = project.rules_python.commit),
)

load("@rules_python//python:pip.bzl", "pip_repositories", "pip3_import")

pip_repositories()

pip3_import(
    name = "yamllint",
    requirements = "//dev/linters/yamllint:requirements.txt",
)

load("@yamllint//:requirements.bzl", "pip_install")

pip_install()

http_archive(
    name = "cf_deployment",
    build_file_content = """
package(default_visibility = ["//visibility:public"])
filegroup(
    name = "cf_deployment",
    srcs = ["cf-deployment.yml", "operations/bits-service/use-bits-service.yml"],
)
""",
    sha256 = project.cf_deployment.sha256,
    strip_prefix = "cf-deployment-{}".format(project.cf_deployment.version),
    url = "https://github.com/cloudfoundry/cf-deployment/archive/v{}.tar.gz".format(project.cf_deployment.version),
)

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

http_archive(
    name = "bazel_skylib",
    sha256 = project.skylib.sha256,
    url = "https://github.com/bazelbuild/bazel-skylib/releases/download/{version}/bazel_skylib-{version}.tar.gz".format(version = project.skylib.version),
)

http_archive(
    name = "com_github_kubernetes_incubator_metrics_server",
    build_file_content = """
package(default_visibility = ["//visibility:public"])
filegroup(
    name = "deploy",
    srcs = glob(["deploy/1.8+/**/*"]),
)
""",
    sha256 = project.metrics_server.sha256,
    strip_prefix = "metrics-server-{}".format(project.metrics_server.version),
    url = "https://github.com/kubernetes-incubator/metrics-server/archive/v{}.tar.gz".format(project.metrics_server.version),
)

http_file(
    name = "mysql_chart",
    sha256 = project.mysql_chart.sha256,
    urls = ["https://kubernetes-charts.storage.googleapis.com/mysql-{}.tgz".format(project.mysql_chart.version)],
)

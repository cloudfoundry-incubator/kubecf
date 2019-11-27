workspace(name = "kubecf")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")
load("//dev/minikube:binary.bzl", "minikube_binary")
load("//rules/external_binary:def.bzl", "external_binary")
load(":def.bzl", "project")

external_binary(
    name = "shellcheck",
    platforms = project.shellcheck.platforms,
)

load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

git_repository(
    name = "rules_python",
    remote = "https://github.com/bazelbuild/rules_python.git",
    commit = project.rules_python.commit,
)

load("@rules_python//python:pip.bzl", "pip_repositories", "pip3_import")

pip_repositories()

pip3_import(
    name = "yamllint",
    requirements = "//dev/linters:requirements.txt",
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

external_binary(
    name = "helm",
    platforms = project.helm.platforms,
)

external_binary(
    name = "kubectl",
    platforms = project.kubernetes.kubectl.platforms
)

minikube_binary(
    name = "minikube",
    platforms = project.minikube.platforms,
    version = project.minikube.version,
)

external_binary(
    name = "kind",
    platforms = project.kind.platforms,
)

external_binary(
    name = "k3s",
    platforms = project.k3s.platforms,
)

http_file(
    name = "local_path_provisioner",
    sha256 = project.local_path_provisioner.sha256,
    urls = [project.local_path_provisioner.url],
)

http_archive(
    name = "bazel_skylib",
    sha256 = project.skylib.sha256,
    url = "https://github.com/bazelbuild/bazel-skylib/releases/download/{version}/bazel-skylib.{version}.tar.gz".format(version = project.skylib.version),
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

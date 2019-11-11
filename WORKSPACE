workspace(name = "kubecf")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")
load("//dev/minikube:binary.bzl", "minikube_binary")
load("//rules/external_binary:def.bzl", "external_binary")
load("//rules/helm:binary.bzl", "helm_binary")
load(":def.bzl", "project")

external_binary(
    name = "shellcheck",
    darwin = project.shellcheck.platforms.darwin,
    linux = project.shellcheck.platforms.linux,
    windows = project.shellcheck.platforms.windows,
)

http_archive(
    name = "cf_deployment",
    build_file_content = """
package(default_visibility = ["//visibility:public"])
filegroup(
    name = "cf_deployment",
    srcs = [
        "cf-deployment.yml",
        "operations/bits-service/use-bits-service.yml",
        "operations/use-external-blobstore.yml",
        "operations/use-s3-blobstore.yml",
        "operations/bits-service/configure-bits-service-s3.yml"
    ],
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

helm_binary(
    name = "helm",
    platforms = project.helm.platforms,
    version = project.helm.version,
)

external_binary(
    name = "kubectl",
    darwin = project.kubernetes.kubectl.platforms.darwin,
    linux = project.kubernetes.kubectl.platforms.linux,
    windows = project.kubernetes.kubectl.platforms.windows,
)

minikube_binary(
    name = "minikube",
    platforms = project.minikube.platforms,
    version = project.minikube.version,
)

external_binary(
    name = "kind",
    darwin = project.kind.platforms.darwin,
    linux = project.kind.platforms.linux,
    windows = project.kind.platforms.windows,
)

external_binary(
    name = "k3s",
    linux = project.k3s,
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

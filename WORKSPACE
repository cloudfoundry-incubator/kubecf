workspace(name = "scf")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//rules/helm:binary.bzl", "helm_binary")
load("//rules/kubectl:binary.bzl", "kubectl_binary")
load("//dev/minikube:binary.bzl", "minikube_binary")
load("//dev/kind:binary.bzl", "kind_binary")
load(":def.bzl", "project")

http_archive(
    name = "cf_deployment",
    build_file_content = """
package(default_visibility = ["//visibility:public"])
filegroup(
    name = "cf_deployment",
    srcs = ["cf-deployment.yml"],
)
""",
    sha256 = project.cf_deployment.sha256,
    strip_prefix = "cf-deployment-{}".format(project.cf_deployment.version),
    url = "https://github.com/cloudfoundry/cf-deployment/archive/v{}.tar.gz".format(project.cf_deployment.version),
)

helm_binary(
    name = "helm",
    version = project.helm.version,
    platforms = project.helm.platforms,
)

kubectl_binary(
    name = "kubectl",
    version = project.kubernetes.version,
    platforms = project.kubernetes.platforms,
)

minikube_binary(
    name = "minikube",
    version = project.minikube.version,
    platforms = project.minikube.platforms,
)

kind_binary(
    name = "kind",
    version = project.kind.version,
    platforms = project.kind.platforms,
)

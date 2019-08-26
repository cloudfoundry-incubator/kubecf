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
    srcs = ["cf-deployment.yml", "operations/bits-service/use-bits-service.yml"],
)
""",
    sha256 = project.cf_deployment.sha256,
    strip_prefix = "cf-deployment-{}".format(project.cf_deployment.version),
    url = "https://github.com/cloudfoundry/cf-deployment/archive/v{}.tar.gz".format(project.cf_deployment.version),
)

helm_binary(
    name = "helm",
    platforms = project.helm.platforms,
    version = project.helm.version,
)

kubectl_binary(
    name = "kubectl",
    platforms = project.kubernetes.platforms,
    version = project.kubernetes.version,
)

minikube_binary(
    name = "minikube",
    platforms = project.minikube.platforms,
    version = project.minikube.version,
)

kind_binary(
    name = "kind",
    platforms = project.kind.platforms,
    version = project.kind.version,
)

skylib_version = "0.8.0"

http_archive(
    name = "bazel_skylib",
    sha256 = "2ef429f5d7ce7111263289644d233707dba35e39696377ebab8b0bc701f7818e",
    url = "https://github.com/bazelbuild/bazel-skylib/releases/download/{}/bazel-skylib.{}.tar.gz".format(skylib_version, skylib_version),
)

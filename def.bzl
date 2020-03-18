"""
Project-wide constant definitions
"""
project = struct(
    deployment_name = "kubecf",
    namespace = "kubecf",
    cf_operator_namespace = "cf-operator",

    # External binaries; see external_binary() invocation in WORKSPACE.
    external_binaries = {
        "docker": struct(
            sha256 = {
                "linux":   "50cdf38749642ec43d6ac50f4a3f1f7f6ac688e8d8b4e1c5b7be06e1a82f06e9",
            },
            url = {
                "linux":   "https://download.docker.com/linux/static/stable/x86_64/docker-{version}.tgz",
            },
            version = "19.03.5",
        ),
        "helm": struct(
            sha256 = {
                "darwin":  "5e27bc6ecf838ed28a6a480ee14e6bec137b467a56f427dbc3cf995f9bdcf85c",
                "linux":   "fc75d62bafec2c3addc87b715ce2512820375ab812e6647dc724123b616586d6",
                "windows": "c52065cb70ad9d88b195638e1591db64852f4ad150448e06fca907d47a07fe4c",
            },
            url = {
                "darwin":  "https://get.helm.sh/helm-v{version}-darwin-amd64.tar.gz",
                "linux":   "https://get.helm.sh/helm-v{version}-linux-amd64.tar.gz",
                "windows": "https://get.helm.sh/helm-v{version}-windows-amd64.zip",
            },
            version = "3.0.3",
        ),
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
        "k3s": struct(
            sha256 = {
                "linux":   "9f8bea3fa6f88066ca51cc896000aab2794e3f585d6fc982dd5aa7da8ee9fe85",
            },
            url = {
                "linux":   "https://github.com/rancher/k3s/releases/download/v{version}/k3s",
            },
            version = "0.9.1",
        ),
        "kind": struct(
            sha256 = {
                "darwin":  "eba1480b335f1fd091bf3635dba3f901f9ebd9dc1fb32199ca8a6aaacf69691e",
                "linux":   "b68e758f5532db408d139fed6ceae9c1400b5137182587fc8da73a5dcdb950ae",
                "windows": "f022a4800363bd4a0c17ee84b58d3e5f654a945dcaf5f66e2c1c230e417b05fb",
            },
            url = {
                "darwin":  "https://github.com/kubernetes-sigs/kind/releases/download/v{version}/kind-darwin-amd64",
                "linux":   "https://github.com/kubernetes-sigs/kind/releases/download/v{version}/kind-linux-amd64",
                "windows": "https://github.com/kubernetes-sigs/kind/releases/download/v{version}/kind-windows-amd64",
            },
            version = "0.6.0",
        ),
        "kubectl": struct(
            sha256 = {
                "darwin":  "1b8e747984ae3f9aa5a199bd444823d703dcd4dbf0617347b3b3aea254ada7b1",
                "linux":   "522115e0f11d83c08435a05e76120c89ea320782ccaff8e301bd14588ec50145",
                "windows": "cd134c5746e39b985df979a944876c0d61ae88e79d954f8534a66bc84cd8a7fb",
            },
            url = {
                "darwin":  "https://storage.googleapis.com/kubernetes-release/release/v{version}/bin/darwin/amd64/kubectl",
                "linux":   "https://storage.googleapis.com/kubernetes-release/release/v{version}/bin/linux/amd64/kubectl",
                "windows": "https://storage.googleapis.com/kubernetes-release/release/v{version}/bin/windows/amd64/kubectl.exe",
            },
            version = "1.15.6",
        ),
        "minikube": struct(
            sha256 = {
                "darwin":  "5ea5168a80597ee6221bf50a524429a24a37f0c0f36725e6b297dc5a7a6a2105",
                "linux":   "eabd027438953d29a4b0f7b810c801919cc13bef3ebe7aff08c9534ac2b091ab",
                "windows": "79d66c874cfe3497656e9ba191680cc95abd92d2f722b10de38f00b76ef82393",
            },
            url = {
                "darwin":  "https://storage.googleapis.com/minikube/releases/v{version}/minikube-darwin-amd64",
                "linux":   "https://storage.googleapis.com/minikube/releases/v{version}/minikube-linux-amd64",
                "windows": "https://storage.googleapis.com/minikube/releases/v{version}/minikube-windows-amd64.exe",
            },
            version = "1.6.2",
        ),
        "shellcheck": struct(
            sha256 = {
                "darwin":  "a5d77cbe4c3e92916bce712b959f6d54392f94bcf8ea84f80ba425a9e72e2afe",
                "linux":   "c37d4f51e26ec8ab96b03d84af8c050548d7288a47f755ffb57706c6c458e027",
                "windows": "8aafdeff31095613308e92ce6a13e3c41249b51e757fd4fcdfdfc7a81d29286a",
            },
            url = {
                "darwin":  "https://storage.googleapis.com/shellcheck/shellcheck-v{version}.darwin-x86_64",
                "linux":   "https://storage.googleapis.com/shellcheck/shellcheck-v{version}.linux-x86_64",
                "windows": "https://storage.googleapis.com/shellcheck/shellcheck-v{version}.exe",
            },
            version = "0.7.0",
        ),
        "yq": struct(
            sha256 = {
                "darwin":  "06732685917646c0bbba8cc17386cd2a39b214ad3cd128fb4b8b410ed069101c",
                "linux":   "754c6e6a7ef92b00ef73b8b0bb1d76d651e04d26aa6c6625e272201afa889f8b",
                "windows": "bdfd2a00bab3d8171edf57aaf4e9a2f7d0395e7a36d42b07f0e35503c00292a3",
            },
            url = {
                "darwin":  "https://github.com/mikefarah/yq/releases/download/{version}/yq_darwin_amd64",
                "linux":   "https://github.com/mikefarah/yq/releases/download/{version}/yq_linux_amd64",
                "windows": "https://github.com/mikefarah/yq/releases/download/{version}/yq_windows_amd64.exe",
            },
            version = "2.4.1",
        ),
    },

    # External bazel libraries; see http_archive() invocation in WORKSPACE.
    bazel_libs = {
        "bazel_skylib": struct(
            urls = [
                "https://github.com/bazelbuild/bazel-skylib/releases/download/{version}/bazel_skylib-{version}.tar.gz",
            ],
            version = "0.9.0",
            sha256 = "1dde365491125a3db70731e25658dfdd3bc5dbdfd11b840b3e987ecf043c7ca0",
        ),
        "cf_deployment": struct(
            urls = ["https://github.com/cloudfoundry/cf-deployment/archive/v{version}.tar.gz"],
            version = "12.33.0",
            sha256 = "e411e8a2e770e9e0c5ecff4d39d0f1e479a67fe150130c339de16fc6583b160a",
            strip_prefix = "cf-deployment-{version}",
            build_file_content = """
package(default_visibility = ["//visibility:public"])
files = [
    "cf-deployment.yml",
    "operations/bits-service/use-bits-service.yml",
]
filegroup(
    name = "cf_deployment",
    srcs = files,
)
exports_files(files)
""",
        ),
        "com_github_kubernetes_incubator_metrics_server": struct(
            urls = ["https://github.com/kubernetes-incubator/metrics-server/archive/v{version}.tar.gz"],
            version = "0.3.6",
            sha256 = "cb0626b297eeb14be20f53896bc0cd68b32d20a4e4b6c8becdef625e322a54ed",
            strip_prefix = "metrics-server-{version}",
            build_file_content = """
package(default_visibility = ["//visibility:public"])
filegroup(
    name = "deploy",
    srcs = glob(["deploy/1.8+/**/*"]),
)
""",
        ),
        "rules_python": struct(
            urls = ["https://github.com/bazelbuild/rules_python/archive/{version}.tar.gz"],
            version = "94677401bc56ed5d756f50b441a6a5c7f735a6d4",
            sha256 = "acbd018f11355ead06b250b352e59824fbb9e77f4874d250d230138231182c1c",
            strip_prefix = "rules_python-{version}",
        ),
        "rules_gomplate": struct(
            sha256 = "5f2c173824020dea6923e0fa20d13df4a1d4cbe264acc009efa41f8a1a50e7d4",
            strip_prefix = "rules_gomplate-{version}",
            urls = ["https://github.com/codelogia/rules_gomplate/archive/{version}.tar.gz"],
            version = "3ab8ff7a25d9c13c8a9d2c5a122241c745a92570",
        ),
    },

    # Additional files we need to download
    external_files = {
        "cf_operator": struct(
            urls = ["https://s3.amazonaws.com/cf-operators/release/helm-charts/cf-operator-{version}.tgz"],
            sha256 = "522a8d3fe480db90f2fb3b4a2fa62a5aed60c1d5eb526e6f627f0e70dbba2434",
            version = "3.3.0%2B0.gf32b521e",
        ),
        "kube_dashboard": struct(
            urls = ["https://raw.githubusercontent.com/kubernetes/dashboard/{version}/aio/deploy/recommended.yaml"],
            sha256 = "f849252870818a2971dfc3c4f8a8c5f58a57606bc2b5f221d7ab693e1d1190e0",
            version = "v2.0.0-beta1",
        ),
        "local_path_provisioner": struct(
            urls = ["https://raw.githubusercontent.com/rancher/local-path-provisioner/{version}/deploy/local-path-storage.yaml"],
            sha256 = "df88b9a38420bb6d286953e06766abbc587e57f1f4eb5cb1c749fa53488cb4f7",
            version = "58cafaccef6645e135664053545ff94cb4bc4224",
        ),
        "mysql_chart": struct(
            urls = ["https://kubernetes-charts.storage.googleapis.com/mysql-{version}.tgz"],
            sha256 = "9ef4ce3693eb2a7428598f9dae833ee546eac9c105b4005c6d7375c55e33bdff",
            version = "1.3.3",
        ),
        "weave_container_network_plugin": struct(
            urls = ["https://github.com/weaveworks/weave/releases/download/{version}/weave-daemonset-k8s-1.11.yaml"],
            sha256 = "3f6d84c16f46dd57a362446dfa8e313d9e401b0cabafef10da280c634a00ac0f",
            version = "v2.6.0",
        ),
    },

    # Generic dependencies
    kubernetes = struct(
        version = "1.15.6",
    ),
)

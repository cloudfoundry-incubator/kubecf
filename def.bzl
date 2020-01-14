project = struct(
    deployment_name = "kubecf",
    namespace = "kubecf",
    chart_version = "0.1.0",
    app_version = "0.1.0",
    cf_deployment = struct(
        version = "12.18.0",
        sha256 = "1aeb7fa2bbd78ac4837c2aeaa4b9dc9567bc498f08f7fd744da556e672788991",
    ),
    cf_operator = struct(
        chart = struct(
            url = "https://s3.amazonaws.com/cf-operators/helm-charts/cf-operator-v1.0.3-0.g5dd886a5.tgz",
            sha256 = "17f34a4d741b6b653210efece7a894037dbf45d73b2655edc160b8d7a5994065",
        ),
    ),
    helm = struct(
        platforms = {
            "darwin": {
                "url": "https://get.helm.sh/helm-v2.16.1-darwin-amd64.tar.gz",
                "sha256": "34fc397ec4a992a451d130a962944315ca782242bbd05a8d732a2e74ca2b9153",
            },
            "linux": {
                "url": "https://get.helm.sh/helm-v2.16.1-linux-amd64.tar.gz",
                "sha256": "7eebaaa2da4734242bbcdced62cc32ba8c7164a18792c8acdf16c77abffce202",
            },
            "windows": {
                "url": "https://get.helm.sh/helm-v2.16.1-windows-amd64.zip",
                "sha256": "414d09b2559316c3dcb81cc448ba44cbbbf54a08a475998211d8dbe7217dd138",
            },
        },
    ),
    kubernetes = struct(
        version = "1.15.6",
    ),
    kubectl = struct(
        platforms = {
            "darwin": {
                "url": "https://storage.googleapis.com/kubernetes-release/release/v1.15.6/bin/darwin/amd64/kubectl",
                "sha256": "1b8e747984ae3f9aa5a199bd444823d703dcd4dbf0617347b3b3aea254ada7b1",
            },
            "linux": {
                "url": "https://storage.googleapis.com/kubernetes-release/release/v1.15.6/bin/linux/amd64/kubectl",
                "sha256": "522115e0f11d83c08435a05e76120c89ea320782ccaff8e301bd14588ec50145",
            },
            "windows": {
                "url": "https://storage.googleapis.com/kubernetes-release/release/v1.15.6/bin/windows/amd64/kubectl.exe",
                "sha256": "cd134c5746e39b985df979a944876c0d61ae88e79d954f8534a66bc84cd8a7fb",
            },
        },
    ),
    minikube = struct(
        version = "1.6.2",
        platforms = [
            {
                "platform": "linux",
                "sha256": "eabd027438953d29a4b0f7b810c801919cc13bef3ebe7aff08c9534ac2b091ab",
            },
            {
                "platform": "darwin",
                "sha256": "5ea5168a80597ee6221bf50a524429a24a37f0c0f36725e6b297dc5a7a6a2105",
            },
            {
                "platform": "windows",
                "sha256": "79d66c874cfe3497656e9ba191680cc95abd92d2f722b10de38f00b76ef82393",
            },
        ],
    ),
    kind = struct(
        platforms = {
            "darwin": {
                "url": "https://github.com/kubernetes-sigs/kind/releases/download/v0.6.0/kind-darwin-amd64",
                "sha256": "eba1480b335f1fd091bf3635dba3f901f9ebd9dc1fb32199ca8a6aaacf69691e",
            },
            "linux": {
                "url": "https://github.com/kubernetes-sigs/kind/releases/download/v0.6.0/kind-linux-amd64",
                "sha256": "b68e758f5532db408d139fed6ceae9c1400b5137182587fc8da73a5dcdb950ae",
            },
            "windows": {
                "url": "https://github.com/kubernetes-sigs/kind/releases/download/v0.6.0/kind-windows-amd64",
                "sha256": "f022a4800363bd4a0c17ee84b58d3e5f654a945dcaf5f66e2c1c230e417b05fb",
            },
        },
    ),
    k3s = struct(
        platforms = {
            "linux": {
                "url": "https://github.com/rancher/k3s/releases/download/v0.9.1/k3s",
                "sha256": "9f8bea3fa6f88066ca51cc896000aab2794e3f585d6fc982dd5aa7da8ee9fe85",
            }
        },
    ),
    docker = struct(
        platforms = {
            "linux": {
                "url": "https://download.docker.com/linux/static/stable/x86_64/docker-19.03.5.tgz",
                "sha256": "50cdf38749642ec43d6ac50f4a3f1f7f6ac688e8d8b4e1c5b7be06e1a82f06e9",
            },
        },
    ),
    local_path_provisioner = struct(
        url = "https://raw.githubusercontent.com/rancher/local-path-provisioner/58cafaccef6645e135664053545ff94cb4bc4224/deploy/local-path-storage.yaml",
        sha256 = "df88b9a38420bb6d286953e06766abbc587e57f1f4eb5cb1c749fa53488cb4f7",
    ),
    kube_dashboard = struct(
        url = "https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta1/aio/deploy/recommended.yaml",
        sha256 = "f849252870818a2971dfc3c4f8a8c5f58a57606bc2b5f221d7ab693e1d1190e0",
    ),
    skylib = struct(
        version = "0.9.0",
        sha256 = "1dde365491125a3db70731e25658dfdd3bc5dbdfd11b840b3e987ecf043c7ca0",
    ),
    metrics_server = struct(
        version = "0.3.6",
        sha256 = "cb0626b297eeb14be20f53896bc0cd68b32d20a4e4b6c8becdef625e322a54ed",
    ),
    shellcheck = struct(
        platforms = {
            "darwin": {
                "url": "https://storage.googleapis.com/shellcheck/shellcheck-v0.7.0.darwin-x86_64",
                "sha256": "a5d77cbe4c3e92916bce712b959f6d54392f94bcf8ea84f80ba425a9e72e2afe",
            },
            "linux": {
                "url": "https://storage.googleapis.com/shellcheck/shellcheck-v0.7.0.linux-x86_64",
                "sha256": "c37d4f51e26ec8ab96b03d84af8c050548d7288a47f755ffb57706c6c458e027",
            },
            "windows": {
                "url": "https://storage.googleapis.com/shellcheck/shellcheck-v0.7.0.exe",
                "sha256": "8aafdeff31095613308e92ce6a13e3c41249b51e757fd4fcdfdfc7a81d29286a",
            },
        },
    ),
    rules_python = struct(
        commit = "94677401bc56ed5d756f50b441a6a5c7f735a6d4",
        sha256 = "acbd018f11355ead06b250b352e59824fbb9e77f4874d250d230138231182c1c",
    ),
    mysql_chart = struct(
        version = "1.3.3",
        sha256 = "9ef4ce3693eb2a7428598f9dae833ee546eac9c105b4005c6d7375c55e33bdff",
    ),
    jq = struct(
        platforms = {
            "darwin": {
                "url": "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-osx-amd64",
                "sha256": "5c0a0a3ea600f302ee458b30317425dd9632d1ad8882259fcaf4e9b868b2b1ef",
            },
            "linux": {
                "url": "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64",
                "sha256": "af986793a515d500ab2d35f8d2aecd656e764504b789b66d7e1a0b727a124c44",
            },
            "windows": {
                "url": "https://github.com/stedolan/jq/releases/download/jq-1.6/jq-win64.exe",
                "sha256": "a51d36968dcbdeabb3142c6f5cf9b401a65dc3a095f3144bd0c118d5bb192753",
            },
        },
    ),
    yq = struct(
        platforms = {
            "darwin": {
                "url": "https://github.com/mikefarah/yq/releases/download/2.4.1/yq_darwin_amd64",
                "sha256": "06732685917646c0bbba8cc17386cd2a39b214ad3cd128fb4b8b410ed069101c",
            },
            "linux": {
                "url": "https://github.com/mikefarah/yq/releases/download/2.4.1/yq_linux_amd64",
                "sha256": "754c6e6a7ef92b00ef73b8b0bb1d76d651e04d26aa6c6625e272201afa889f8b",
            },
            "windows": {
                "url": "https://github.com/mikefarah/yq/releases/download/2.4.1/yq_windows_amd64.exe",
                "sha256": "bdfd2a00bab3d8171edf57aaf4e9a2f7d0395e7a36d42b07f0e35503c00292a3",
            },
        },
    ),
    drone = struct(
        server = struct(
            app_name = "kubecf-drone-ci-server",
            image = struct(
                version = 1,
                sha256 = "0fc552775eb2ab2a36a434f2e7ba3a8f140ee1841eda6e94165265ed3e2ee683",
            ),
            plugins = struct(
                convert_starlark = struct(
                    image = struct(
                        sha256 = "0cb9f8386b9c7862c2bf272b77ce63afa15785592818264c35bfacf1bb0e1b92",
                    ),
                ),
            ),
        ),
        runner = struct(
            capacity = 1,
            network = struct(
                name = "kubecf-drone-ci",
            ),
            image = struct(
                version = 1,
                sha256 = "eb09cdffd60b685fc76dc15c019a74829ba1632c27cf949ce271a792e7386597",
            ),
            rpc = struct(
                host = "kubecf-drone-ci-server.herokuapp.com",
                proto = "https",
            ),
        ),
    ),
)

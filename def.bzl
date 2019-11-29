project = struct(
    deployment_name = "kubecf",
    namespace = "kubecf",
    chart_version = "3.0.0",
    app_version = "2.0",
    cf_deployment = struct(
        version = "8.0.0",
        sha256 = "289f6c5a116eef4b16b228d07d55517dc20f76199c1476036fc0ade5a08a3e1b",
    ),
    cf_operator = struct(
        chart = struct(
            url = "https://s3.amazonaws.com/cf-operators/helm-charts/cf-operator-v0.4.2-167.g34209e10.tgz",
            sha256 = "9ecdb9b452d41dd83a070179b14333054b558daec923d58e29f96ced4af4e208",
        ),
        namespace = "cfo",
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
    ),
    minikube = struct(
        version = "1.3.0",
        platforms = [
            {
                "platform": "linux",
                "sha256": "5aa7c5f0b6dd09348f7e2435b9618f6a916fbb573580619b393b514258771eab",
            },
            {
                "platform": "darwin",
                "sha256": "5bda29e2d990bb8ac9da1767143e228772adc45507d22a49b5af70b03e7db682",
            },
            {
                "platform": "windows",
                "sha256": "d808b6e42e6f53c9338d135a352bebd4469634f33646d06e7cad3569330225cb",
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
    local_path_provisioner = struct(
        url = "https://raw.githubusercontent.com/rancher/local-path-provisioner/58cafaccef6645e135664053545ff94cb4bc4224/deploy/local-path-storage.yaml",
        sha256 = "df88b9a38420bb6d286953e06766abbc587e57f1f4eb5cb1c749fa53488cb4f7",
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
    yaml2json = struct(
        platforms = {
            "darwin": {
                "url": "https://github.com/bronze1man/yaml2json/releases/download/v1.3/yaml2json_darwin_amd64",
                "sha256": "5ea7e2bddf13721e68ae38b81093e8d539456af2cd22c7a1b0923e45a765c636",
            },
            "linux": {
                "url": "https://github.com/bronze1man/yaml2json/releases/download/v1.3/yaml2json_linux_amd64",
                "sha256": "e792647dd757c974351ea4ad35030852af97ef9bbbfb9594f0c94317e6738e55",
            },
            "windows": {
                "url": "https://github.com/bronze1man/yaml2json/releases/download/v1.3/yaml2json_windows_amd64.exe",
                "sha256": "a73fb27e36e30062c48dc0979c96afbbe25163e0899f6f259b654d56fda5cc26",
            },
        },
    ),
)

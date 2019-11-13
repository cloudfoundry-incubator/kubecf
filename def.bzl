project = struct(
    namespace = "kubecf",
    cf_deployment = struct(
        version = "8.0.0",
        sha256 = "289f6c5a116eef4b16b228d07d55517dc20f76199c1476036fc0ade5a08a3e1b",
    ),
    cf_operator = struct(
        chart = struct(
            url = "https://s3.amazonaws.com/cf-operators/helm-charts/cf-operator-v0.4.2-147.gb88e4296.tgz",
            sha256 = "7cc0c23df3aa5fb7f2075e3dbd77d2dc51c1ee283060ae9cb46ed680b1deb1d0",
        ),
        namespace = "cfo",
    ),
    helm = struct(
        version = "2.14.1",
        platforms = [
            {
                "platform": "linux",
                "sha256": "804f745e6884435ef1343f4de8940f9db64f935cd9a55ad3d9153d064b7f5896",
            },
            {
                "platform": "darwin",
                "sha256": "392ec847ecc5870a48a39cb0b8d13c8aa72aaf4365e0315c4d7a2553019a451c",
            },
            {
                "platform": "windows",
                "sha256": "604780d3fabeb27e7ab7a30c6e29ce64bcd2203501ea35e5231c97965b0255a0",
            },
        ],
    ),
    kubernetes = struct(
        version = "1.14.6",
        kubectl = struct(
            platforms = struct(
                darwin = {
                    "url": "https://storage.googleapis.com/kubernetes-release/release/v1.14.6/bin/darwin/amd64/kubectl",
                    "sha256": "de42dd22f67c135b749c75f389c70084c3fe840e3d89a03804edd255ac6ee829",
                },
                linux = {
                    "url": "https://storage.googleapis.com/kubernetes-release/release/v1.14.6/bin/linux/amd64/kubectl",
                    "sha256": "5f8e8d8de929f64b8f779d0428854285e1a1c53a02cc2ad6b1ce5d32eefad25c",
                },
                windows = {
                    "url": "https://storage.googleapis.com/kubernetes-release/release/v1.14.6/bin/windows/amd64/kubectl.exe",
                    "sha256": "3aa2d64f5eb9564622ddabe5f0a6c12d13d9dda90125f5a56ce41779395fa6f5",
                },
            ),
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
        platforms = struct(
            darwin = {
                "url": "https://github.com/kubernetes-sigs/kind/releases/download/v0.5.1/kind-darwin-amd64",
                "sha256": "b6a8fe2b3b53930a1afa4f91b033cdc24b0f6c628d993abaa9e40b57d261162a",
            },
            linux = {
                "url": "https://github.com/kubernetes-sigs/kind/releases/download/v0.5.1/kind-linux-amd64",
                "sha256": "9a64f1774cdf24dad5f92e1299058b371c4e3f09d2f9eb281e91ed0777bd1e13",
            },
            windows = {
                "url": "https://github.com/kubernetes-sigs/kind/releases/download/v0.5.1/kind-windows-amd64",
                "sha256": "df327d1e7f8bb41dfd5b1a69c5bc7a8d4bad95bb933562ca367a3a45b6c6ca04",
            },
        ),
    ),
    k3s = {
        "url": "https://github.com/rancher/k3s/releases/download/v0.9.1/k3s",
        "sha256": "9f8bea3fa6f88066ca51cc896000aab2794e3f585d6fc982dd5aa7da8ee9fe85",
    },
    local_path_provisioner = struct(
        url = "https://raw.githubusercontent.com/rancher/local-path-provisioner/58cafaccef6645e135664053545ff94cb4bc4224/deploy/local-path-storage.yaml",
        sha256 = "df88b9a38420bb6d286953e06766abbc587e57f1f4eb5cb1c749fa53488cb4f7",
    ),
    skylib = struct(
        version = "0.8.0",
        sha256 = "2ef429f5d7ce7111263289644d233707dba35e39696377ebab8b0bc701f7818e",
    ),
    metrics_server = struct(
        version = "0.3.3",
        sha256 = "9a8a204a46a4159f5a6bcb508cc51b49cdfb15aa5a034c7910ddca5a435097d4",
    ),
    shellcheck = struct(
        platforms = struct(
            darwin = {
                "url": "https://storage.googleapis.com/shellcheck/shellcheck-v0.7.0.darwin-x86_64",
                "sha256": "a5d77cbe4c3e92916bce712b959f6d54392f94bcf8ea84f80ba425a9e72e2afe",
            },
            linux = {
                "url": "https://storage.googleapis.com/shellcheck/shellcheck-v0.7.0.linux-x86_64",
                "sha256": "c37d4f51e26ec8ab96b03d84af8c050548d7288a47f755ffb57706c6c458e027",
            },
            windows = {
                "url": "https://storage.googleapis.com/shellcheck/shellcheck-v0.7.0.exe",
                "sha256": "8aafdeff31095613308e92ce6a13e3c41249b51e757fd4fcdfdfc7a81d29286a",
            },
        ),
    ),
)

project = struct(
    namespace = "scf", # The namespace used across the project.
    cf_deployment = struct(
        version = "8.0.0",
        sha256 = "289f6c5a116eef4b16b228d07d55517dc20f76199c1476036fc0ade5a08a3e1b",
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
        platforms = [
            {
                "platform": "linux",
                "sha256": "5f8e8d8de929f64b8f779d0428854285e1a1c53a02cc2ad6b1ce5d32eefad25c",
            },
            {
                "platform": "darwin",
                "sha256": "de42dd22f67c135b749c75f389c70084c3fe840e3d89a03804edd255ac6ee829",
            },
            {
                "platform": "windows",
                "sha256": "3aa2d64f5eb9564622ddabe5f0a6c12d13d9dda90125f5a56ce41779395fa6f5",
            },
        ],
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
        version = "0.4.0",
        platforms = [
            {
                "platform": "linux",
                "sha256": "a97f7d6d97bc0e261ea85433ca564269f117baf0fae051f16b296d2d7541f8dd",
            },
            {
                "platform": "darwin",
                "sha256": "023f1886207132dcfc62139a86f09488a79210732b00c9ec6431d6f6b7e9d2d3",
            },
            {
                "platform": "windows",
                "sha256": "58add85c8c1a2d5df7564f814076db5f334b6164098e899bba0c6176d11c9940",
            },
        ],
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

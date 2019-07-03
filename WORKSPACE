workspace(name = "scf")

load("//rules/helm:binary.bzl", "helm_binary")

helm_binary(
    name = "helm",
    version = "v2.14.1",
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
    ]
)

"""An extension with the workspace dependency declarations."""

dependencies = [
    {
        "name": "jq",
        "url": {
            "darwin": "https://github.com/stedolan/jq/releases/download/jq-{version}/jq-osx-amd64",
            "linux": "https://github.com/stedolan/jq/releases/download/jq-{version}/jq-linux64",
            "windows": "https://github.com/stedolan/jq/releases/download/jq-{version}/jq-win64.exe",
        },
        "sha256": {
            "darwin": "5c0a0a3ea600f302ee458b30317425dd9632d1ad8882259fcaf4e9b868b2b1ef",
            "linux": "af986793a515d500ab2d35f8d2aecd656e764504b789b66d7e1a0b727a124c44",
            "windows": "a51d36968dcbdeabb3142c6f5cf9b401a65dc3a095f3144bd0c118d5bb192753",
        },
        "version": "1.6",
    },
    {
        "name": "yq",
        "url": {
            "darwin": "https://github.com/mikefarah/yq/releases/download/{version}/yq_darwin_amd64",
            "linux": "https://github.com/mikefarah/yq/releases/download/{version}/yq_linux_amd64",
            "windows": "https://github.com/mikefarah/yq/releases/download/{version}/yq_windows_amd64.exe",
        },
        "sha256": {
            "darwin": "33178f687608446d1d7db327f75d102355ba14b77759931acac18f2c9f252a91",
            "linux": "e70e482e7ddb9cf83b52f5e83b694a19e3aaf36acf6b82512cbe66e41d569201",
            "windows": "9137dd05ffe568ea8438411e426ed039cfbfb317339f335c778cb53919f28277",
        },
        "version": "3.3.0",
    },
]

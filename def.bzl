project = struct(
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
        version = "1.13.8",
        platforms = [
            {
                "platform": "linux",
                "sha256": "28919b49b8d9d9aee98001556952cf7d36aae6d4875f4f305399590ff9849d6e",
            },
            {
                "platform": "darwin",
                "sha256": "7b788747a5536f5156b37c71489b8a5c18bd6ab8315db84d579e47db1eb9d56a",
            },
            {
                "platform": "windows",
                "sha256": "a3b2895aa5d5344971e55126f8b33b65f8b7c3b2ef8b07a1e3d80b06037d0549",
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
)

# shellcheck shell=bash
# shellcheck disable=SC2034

TOOLS+=(minikube)

MINIKUBE_VERSION="1.9.2"

MINIKUBE_URL_DARWIN="https://storage.googleapis.com/minikube/releases/v{version}/minikube-darwin-amd64"
MINIKUBE_URL_LINUX="https://storage.googleapis.com/minikube/releases/v{version}/minikube-linux-amd64"
MINIKUBE_URL_WINDOWS="https://storage.googleapis.com/minikube/releases/v{version}/minikube-windows-amd64.exe"

MINIKUBE_SHA256_DARWIN="f27016246850b3145e1509e98f7ed060fd9575ac4d455c7bdc15277734372e85"
MINIKUBE_SHA256_LINUX="3121f933bf8d608befb24628a045ce536658738c14618504ba46c92e656ea6b5"
MINIKUBE_SHA256_WINDOWS="426586f33d88a484fdc5a3b326b0651d57860e9305a4f9d4180640e3beccaf6b"

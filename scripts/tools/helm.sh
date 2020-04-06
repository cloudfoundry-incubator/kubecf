# shellcheck shell=bash
# shellcheck disable=SC2034

TOOLS+=(helm)

HELM_URL_DARWIN="https://get.helm.sh/helm-v{version}-darwin-amd64.tar.gz"
HELM_SHA256_DARWIN="5e27bc6ecf838ed28a6a480ee14e6bec137b467a56f427dbc3cf995f9bdcf85c"

HELM_URL_LINUX="https://get.helm.sh/helm-v{version}-linux-amd64.tar.gz"
HELM_SHA256_LINUX="fc75d62bafec2c3addc87b715ce2512820375ab812e6647dc724123b616586d6"

HELM_URL_WINDOWS="https://get.helm.sh/helm-v{version}-windows-amd64.zip"
HELM_SHA256_WINDOWS="c52065cb70ad9d88b195638e1591db64852f4ad150448e06fca907d47a07fe4c"

HELM_VERSION="3.0.3"

# shellcheck shell=bash
# shellcheck disable=SC2034

TOOLS+=(bosh)

BOSH_VERSION="6.2.1"

BOSH_URL_DARWIN="https://github.com/cloudfoundry/bosh-cli/releases/download/v{version}/bosh-cli-{version}-darwin-amd64"
BOSH_URL_LINUX="https://github.com/cloudfoundry/bosh-cli/releases/download/v{version}/bosh-cli-{version}-linux-amd64"
BOSH_URL_WINDOWS="https://github.com/cloudfoundry/bosh-cli/releases/download/v{version}/bosh-cli-{version}-windows-amd64.exe"

BOSH_SHA256_DARWIN="1d2ced5edc7a9406616df7ad9c0d4e3ade10d66d33e753885ab8e245c037e280"
BOSH_SHA256_LINUX="ca7580008abfd4942dcb1dd6218bde04d35f727717a7d08a2bc9f7d346bce0f6"
BOSH_SHA256_WINDOWS="77c736c15001b1eb320ae61042fb6c72a1addde143e0a9af703ddda35b2c5bce"

function bosh_version { bosh -v; }

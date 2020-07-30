# shellcheck shell=bash
# shellcheck disable=SC2034

TOOLS+=(cf_operator_url cf_operator_sha256)

function cf_operator_url {
    local url version
    url=$(y2j < dependencies.yaml | jq -r .external_files.cf_operator.url)
    version=$(y2j < dependencies.yaml | jq -r .external_files.cf_operator.version)
    echo "${url//\{version\}/${version}}"
}

function cf_operator_sha256 {
    y2j < dependencies.yaml | jq -r .external_files.cf_operator.sha256
}

CF_OPERATOR_URL_REQUIRES="jq y2j"
CF_OPERATOR_SHA256_REQUIRES="jq y2j"

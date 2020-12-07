#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools cf_operator_url cf_operator_sha256 curl sha256sum

# Set default target file
if [ -z "${TARGET_FILE:-}" ]; then
    VERSION="${VERSION:-$(./scripts/version.sh)}"
    TARGET_FILE="${OUTPUT_DIR}/kubecf-bundle-${VERSION}.tgz"
fi

# Create bundle directory
BUNDLE_DIR="${TEMP_DIR}/bundle"
[ -d "${BUNDLE_DIR}" ] && rm -rf "${BUNDLE_DIR}"
mkdir "${BUNDLE_DIR}"

# Download cf-operator chart
CF_OPERATOR_FILE="${BUNDLE_DIR}/cf-operator.tgz"
CF_OPERATOR_URL="$(cf_operator_url)"
curl -s -L "${CF_OPERATOR_URL}" -o "${CF_OPERATOR_FILE}"

CF_OPERATOR_SHA256="$(cf_operator_sha256)"
if ! echo "${CF_OPERATOR_SHA256} ${CF_OPERATOR_FILE}" | sha256sum --check --status; then
    die "sha256 for ${CF_OPERATOR_URL} does not match ${CF_OPERATOR_SHA256}"
fi

# Build kubecf chart
TARGET_FILE="${BUNDLE_DIR}/kubecf_release.tgz" ./scripts/kubecf-build.sh

# Build bundle
mkdir -p "$(dirname "${TARGET_FILE}")"
tar cfz "${TARGET_FILE}" -C "${BUNDLE_DIR}" .

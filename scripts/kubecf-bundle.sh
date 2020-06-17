#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools curl sha256sum

# Set default target file
if [ -z "${TARGET_FILE:-}" ]; then
    VERSION="$(./scripts/version.sh)"
    TARGET_FILE="${OUTPUT_DIR}/kubecf-bundle-${VERSION}.tgz"
fi

# Create bundle directory
BUNDLE_DIR="${TEMP_DIR}/bundle"
[ -d "${BUNDLE_DIR}" ] && rm -rf "${BUNDLE_DIR}"
mkdir "${BUNDLE_DIR}"

# Download cf-operator chart
CF_OPERATOR_FILE="${BUNDLE_DIR}/cf-operator.tgz"
DOWNLOAD_URL="${CF_OPERATOR_URL//\{version\}/${CF_OPERATOR_VERSION}}"
curl -s -L "${DOWNLOAD_URL}" -o "${CF_OPERATOR_FILE}"

if ! echo "${CF_OPERATOR_SHA256} ${CF_OPERATOR_FILE}" | sha256sum --check --status; then
    die "sha256 for ${DOWNLOAD_URL} does not match ${CF_OPERATOR_SHA256}"
fi

# Build kubecf chart
TARGET_FILE="${BUNDLE_DIR}/kubecf_release.tgz" ./scripts/kubecf-build.sh

# Build bundle
mkdir -p $(dirname "${TARGET_FILE}")
tar cfz "${TARGET_FILE}" -C "${BUNDLE_DIR}" .

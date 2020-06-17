#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools helm

export TARGET_FILE="${TEMP_DIR}/kubecf.tgz"
./scripts/kubecf-build.sh

# The tarball extracts into a kubecf/ subdirectory.
TARGET_DIR="${TEMP_DIR}/kubecf"
[ -d "${TARGET_DIR}" ] && rm -rf "${TARGET_DIR}"
mkdir "${TARGET_DIR}"

tar xfz "${TARGET_FILE}" -C "${TEMP_DIR}"
helm lint "${TARGET_DIR}"

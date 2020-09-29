#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools helm perl

export TARGET_FILE="${TEMP_DIR}/kubecf.tgz"
./scripts/kubecf-build.sh

# The tarball extracts into a kubecf/ subdirectory.
TARGET_DIR="${TEMP_DIR}/kubecf"
[ -d "${TARGET_DIR}" ] && rm -rf "${TARGET_DIR}"
mkdir "${TARGET_DIR}"

tar xfz "${TARGET_FILE}" -C "${TEMP_DIR}"
helm lint "${TARGET_DIR}" --set system_domain=example.com

# Running json schema validator a second time to also check the embedded config files.
# Done in a separate run because the config files are merged here on top of values.yaml,
# which will cause replacement of any arrays.
#
# NOTE: We exclude all config files which contain templating.

# shellcheck disable=SC2046
# We want word splitting with find.
helm template "${TARGET_DIR}" --set system_domain=example.com \
     --values "$(perl -e 'print join ",", @ARGV' -- \
              $(grep -L '{{' $(find "${TARGET_DIR}/config" -type f)))" \
     > /dev/null

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
# Workaround: [Helm lint (v3) doesn't take values files into account during schema validation]
# (https://github.com/helm/helm/issues/7756). Fixed in helm 3.3.0.
perl -p -i -e 's/(system_domain:).*/$1 example.com/' "${TARGET_DIR}/values.yaml"
helm lint "${TARGET_DIR}" --set system_domain=example.com

# Running json schema validator a second time to also check the embedded config files.
# Done in a separate run because the config files are merged here on top of values.yaml,
# which will cause replacement of any arrays. Using `helm template` instead, which also
# runs the validator, but doesn't suffer from bug #7756.

# shellcheck disable=SC2046
# We want word splitting with find.
helm template "${TARGET_DIR}" --set system_domain=example.com \
     --values "$(perl -e 'print join ",", @ARGV' -- $(find "${TARGET_DIR}/config" -type f))" \
     > /dev/null

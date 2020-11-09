#!/usr/bin/env bash

# NEVER SET xtrace!
set -o errexit -o nounset

# Start the Docker daemon.

# shellcheck source=/dev/null
source build-image-resource/assets/common.sh
max_concurrent_downloads=10
max_concurrent_uploads=10
insecure_registries=""
registry_mirror=""
start_docker \
  "${max_concurrent_downloads}" \
  "${max_concurrent_uploads}" \
  "${insecure_registries}" \
  "${registry_mirror}"
trap 'stop_docker' EXIT

# Login to the Docker registry.
echo "${REGISTRY_PASS}" | docker login "${REGISTRY_NAME}" --username "${REGISTRY_USER}" --password-stdin

# Extract the fissile binary.
tar xvf s3.fissile-linux/fissile-*.tgz --directory "/usr/local/bin/"

# Pull the stemcell image referenced in the KUBECF_VALUES
# sle_version: e.g. SLE_15_SP1
sle_version="$(cut -d- -f1 "s3.stemcell-version/${STEMCELL_VERSIONED_FILE##*/}")"
# stemcell_version without the fissile version part, e.g. 27.8
# shellcheck disable=SC2016
stemcell_master_version=${sle_version}-$(yq -r '.stacks.sle15.releases["$defaults"].stemcell.version' "kubecf/${KUBECF_VALUES}" | cut -d- -f1)
stemcell_master_image="${STEMCELL_REPOSITORY}:${stemcell_master_version}"
stemcell_s3_version="$(cat s3.stemcell-version/"${STEMCELL_VERSIONED_FILE##*/}")"
stemcell_s3_image="${STEMCELL_REPOSITORY}:${stemcell_s3_version}"

docker pull "${stemcell_master_image}"
docker pull "${stemcell_s3_image}"

# Get version from the GitHub release that triggered this task
pushd suse_final_release
RELEASE_VERSION=$(cat version)
RELEASE_URL=$(cat url)
RELEASE_SHA=$(sha1sum ./*.tgz | cut -d' ' -f1)
popd

tasks_dir="$(dirname "$0")"
# shellcheck source=/dev/null
source "${tasks_dir}"/build_release.sh
build_release "${REGISTRY_NAME}" "${REGISTRY_ORG}" "${stemcell_master_image}" "${RELEASE_NAME}" "${RELEASE_URL}" "${RELEASE_VERSION}" "${RELEASE_SHA}"

if [ "${stemcell_master_version}" != "${stemcell_s3_version}" ]; then
  build_release "${REGISTRY_NAME}" "${REGISTRY_ORG}" "${stemcell_s3_image}" "${RELEASE_NAME}" "${RELEASE_URL}" "${RELEASE_VERSION}" "${RELEASE_SHA}"
fi

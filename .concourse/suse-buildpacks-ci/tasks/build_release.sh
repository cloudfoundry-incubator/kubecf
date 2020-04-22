#!/usr/bin/env bash

set -o errexit -o nounset

GREEN='\033[0;32m'
NC='\033[0m'

function build_release() {
  registry="${1}"
  organization="${2}"
  stemcell_image="${3}"
  release_name="${4}"
  release_url="${5}"
  release_version="${6}"
  release_sha1="${7}"

  echo -e "Release information:"
  echo -e "  - Release name:    ${GREEN}${release_name}${NC}"
  echo -e "  - Release version: ${GREEN}${release_version}${NC}"
  echo -e "  - Release URL:     ${GREEN}${release_url}${NC}"
  echo -e "  - Release SHA1:    ${GREEN}${release_sha1}${NC}"

  build_args=(
    --stemcell="${stemcell_image}"
    --name="${release_name}"
    --version="${release_version}"
    --url="${release_url}"
    --sha1="${release_sha1}"
    --docker-registry="${registry}"
    --docker-organization="${organization}"
  )

  built_image=$(fissile build release-images --dry-run "${build_args[@]}" | cut -d' ' -f3)
  echo $built_image > built_image/image
  export DOCKER_CLI_EXPERIMENTAL=enabled
  # Only build and push the container image if doesn't exits already.
  if docker manifest inspect "${built_image}" 2>&1 | grep --quiet "no such manifest"; then
      # Build the release image.
      fissile build release-images "${build_args[@]}"
      echo -e "Built image: ${GREEN}${built_image}${NC}"
      docker push "${built_image}"
      docker rmi "${built_image}"
  else
      echo -e "Skipping push for ${GREEN}${built_image}${NC} as it is already present in the registry..."
  fi

  echo '----------------------------------------------------------------------------------------------------'
}

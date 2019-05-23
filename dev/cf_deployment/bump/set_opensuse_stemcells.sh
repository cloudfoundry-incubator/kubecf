#!/usr/bin/env bash

set -o errexit -o nounset

cf_deployment_yaml="deploy/helm/scf/assets/cf-deployment.yml"
dest="deploy/helm/scf/assets/operations/set_opensuse_stemcells.yaml"

printf "# This ops file sets the openSUSE stemcells.\n\n" > "${dest}"

replace() {
  printf "%s\n" "- type: replace" >> "${dest}"
  printf "%s\n" "  path: $1" >> "${dest}"
  printf "%s\n" "  value: $2" >> "${dest}"
  printf "\n" >> "${dest}"
}

replace "/stemcells/alias=default/os" "opensuse-42.3"
replace "/stemcells/alias=default/version" "30.g9c91e77-30.80-7.0.0_257.gb97ced55"

yq -r '.addons[] | select(.include?.stemcell[]? | select(.os? == "ubuntu-xenial")) | .name' "${cf_deployment_yaml}" \
  | xargs \
    --no-run-if-empty \
    --replace='[addon]' \
    printf -- "- type: replace\n  path: /addons/name=[addon]/include/stemcell/os=ubuntu-xenial/os\n  value: opensuse-42.3\n\n" \
  | head -c -1 \
  >> "${dest}"

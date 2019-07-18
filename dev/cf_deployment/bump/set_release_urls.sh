#!/usr/bin/env bash

set -o errexit -o nounset

cf_deployment_yaml="deploy/helm/scf/assets/cf-deployment.yml"
dest="deploy/helm/scf/assets/operations/set_release_urls.yaml"

printf '# This ops file sets the Quarks images for the releases.\n\n' > "${dest}"

yq -r '.releases[].name' "${cf_deployment_yaml}" \
  | xargs \
    --no-run-if-empty \
    --replace='[release]' \
    printf -- '- type: replace\n  path: /releases/name=[release]/url\n  value: docker.io/cfcontainerization\n- type: remove\n  path: /releases/name=[release]/sha1\n\n' \
  | head -c -1 \
  >> "${dest}"

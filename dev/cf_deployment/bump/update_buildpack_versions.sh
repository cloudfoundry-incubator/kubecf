#!/usr/bin/env bash

set -o errexit -o nounset

cf_deployment_yaml="chart/assets/cf-deployment.yml"
dest="chart/assets/operations/instance_groups/api.yaml"

buildpacks=$(yq -r '.instance_groups[].jobs[] | select(.name=="cloud_controller_ng") |.properties.cc.install_buildpacks[].name' "${cf_deployment_yaml}")

for bp in ${buildpacks}; do
  key=$(echo "${bp}" | tr '_' '-')
  version=$(yq -r ".releases[] | select(.name==\"${key}\") | .version" "${cf_deployment_yaml}")

  sed -ri "s/(.*${key}.*)v(.*).zip/\1v${version}.zip/" "${dest}"
done

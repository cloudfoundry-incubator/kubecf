#!/usr/bin/env bash

set -o errexit -o nounset

# shellcheck disable=SC1091
source ".drone/pipelines/default/runtime/binaries.sh"
# shellcheck disable=SC1091
source ".drone/pipelines/default/runtime/config.sh"

kubectl create namespace "${CF_OPERATOR_NAMESPACE}"
bazel run //dev/cf_operator:install_or_upgrade

#!/usr/bin/env bash

set -o errexit -o nounset

workspace=$(bazel info workspace)

# shellcheck disable=SC1090
source "${workspace}/.drone/pipelines/default/runtime/binaries.sh"
# shellcheck disable=SC1090
source "${workspace}/.drone/pipelines/default/runtime/docker.sh"
# shellcheck disable=SC1090
source "${workspace}/.drone/pipelines/default/runtime/config.sh"

docker_max_concurrent_downloads=15
docker_max_concurrent_uploads=15
docker_insecure_registries=""
docker_registry_mirrors=""
start_docker \
  "${docker_max_concurrent_downloads}" \
  "${docker_max_concurrent_uploads}" \
  "${docker_insecure_registries}" \
  "${docker_registry_mirrors}"

trap stop_docker EXIT

bazel run //dev/kind:start

# Deploy
"${workspace}/.drone/pipelines/default/steps/test/deploy/cf_operator.sh"
"${workspace}/.drone/pipelines/default/steps/test/deploy/wait_cf_operator.sh"
"${workspace}/.drone/pipelines/default/steps/test/deploy/kubecf.sh"
"${workspace}/.drone/pipelines/default/steps/test/deploy/wait_kubecf.sh"

# Test
"${workspace}/.drone/pipelines/default/steps/test/tests/smoke_tests.sh"
"${workspace}/.drone/pipelines/default/steps/test/tests/cf_acceptance_tests.sh"

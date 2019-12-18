#!/usr/bin/env bash

set -o errexit -o nounset

# shellcheck disable=SC1091
source ".drone/pipelines/default/runtime/binaries.sh"
# shellcheck disable=SC1091
source ".drone/pipelines/default/runtime/config.sh"

bazel run //dev/kind:start

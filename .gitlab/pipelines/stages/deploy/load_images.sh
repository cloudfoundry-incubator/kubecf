#!/usr/bin/env bash

# This script loads any extra docker images into the cluster

set -o errexit -o nounset -o pipefail

workspace=$(bazel info workspace)

# shellcheck disable=SC1090
source "${workspace}/.gitlab/pipelines/runtime/config.sh"
# shellcheck disable=SC1090
source "${workspace}/.gitlab/pipelines/runtime/binaries.sh"

bazel build //deploy/containers:bundle.tar

"${K3S}" ctr images import bazel-bin/deploy/containers/bundle.tar

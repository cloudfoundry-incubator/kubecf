#!/usr/bin/env bash

set -o errexit -o nounset

# shellcheck disable=SC1090
source "$(bazel info workspace)/.gitlab/pipelines/runtime/config.sh"

bazel build "${KUBECF_CHART_TARGET}"
built_file="$(bazel aquery "${KUBECF_CHART_TARGET}" 2> /dev/null | awk 'match($0, /Outputs: \[(.*)\]/, output){ print output[1] }')"
extension="tgz"
commit_hash="$(git rev-parse --short HEAD)"
release_filename="$(basename "${built_file}" ".${extension}")-${commit_hash}"
if [ -n "$(git status --porcelain)" ]; then
  release_filename="${release_filename}-dirty"
fi

mkdir -p output
cp "${built_file}" "output/${release_filename}.${extension}"

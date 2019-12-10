#!/usr/bin/env bash

set -o errexit -o nounset

workspace=$(bazel info workspace)

# shellcheck disable=SC1090
source "${workspace}/.drone/pipelines/default/runtime/config.sh"

# Given a bazel target, output the file name it generates.
get_output_file() {
  local package="${1}"
  awk '
    BEGIN { wanted_action = false }
    wanted_action && match($0, /^  Outputs: \[(.*)\]/, output) {
      print output[1];
    }
    /^[^ ]/ { wanted_action = 0 }
    /^action.*\.tgz'"'"'$/ {
      wanted_action = 1
    }
  ' <(bazel aquery "${package}:all" 2>/dev/null)
}

mkdir -p output
extension="tgz"
describe="$(git describe --match='$^' --dirty --always)"

# Build the kubecf helm chart
bazel build "${KUBECF_CHART_TARGET}"
built_file="$(get_output_file "${KUBECF_CHART_TARGET%:*}")"
release_filename="$(basename "${built_file}" ".${extension}")-${describe}"
cp "${built_file}" "${workspace}/output/${release_filename}.${extension}"
chmod 0644 "${workspace}/output/${release_filename}.${extension}"

# Build the install bundle (kubecf chart + cf-operator chart)
bazel build "${KUBECF_BUNDLE_TARGET}"
built_file="$(get_output_file "${KUBECF_BUNDLE_TARGET%:*}")"
bundle_filename="$(basename "${built_file}" ".${extension}")-${describe}"
cp "${built_file}" "${workspace}/output/${bundle_filename}.${extension}"
chmod 0644 "${built_file}" "${workspace}/output/${bundle_filename}.${extension}"

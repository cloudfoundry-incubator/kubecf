#!/usr/bin/env bash

set -o errexit -o nounset

workspace=$(bazel info workspace)

# shellcheck disable=SC1090
source "${workspace}/.gitlab/pipelines/runtime/config.sh"

# Given a bazel target, output the file name it generates ending with the given extension.
get_output_file() {
  local package="${1}"
  local extension="${2}"
  awk "
    BEGIN { wanted_action = false }
    wanted_action && match(\$0, /^  Outputs: \\[(.*)\\]/, output) {
      print output[1];
    }
    /^[^ ]/ { wanted_action = 0 }
    /^action.*\\.${extension}'\$/ {
      wanted_action = 1
    }
  " <(bazel aquery "${package}:all" 2>/dev/null)
}

mkdir -p output

# Build the kubecf helm chart
bazel build "${KUBECF_CHART_TARGET}"
built_file="$(get_output_file "${KUBECF_CHART_TARGET%:*}" "tgz")"
built_file_name="$(basename "${built_file}")"
cp "${built_file}" "${workspace}/output/${built_file_name}"
chmod 0644 "${workspace}/output/${built_file_name}"

# Build the install bundle (kubecf chart + cf-operator chart)
bazel build "${KUBECF_BUNDLE_TARGET}"
built_file="$(get_output_file "${KUBECF_BUNDLE_TARGET%:*}" "tgz")"
built_file_name="$(basename "${built_file}")"
cp "${built_file}" "${workspace}/output/${built_file_name}"
chmod 0644 "${workspace}/output/${built_file_name}"

# Build the txt file that contains the chart verison.
bazel build "${KUBECF_VERSION_TARGET}"
built_file="$(get_output_file "${KUBECF_VERSION_TARGET%:*}" "txt")"
built_file_name="$(basename "${built_file}")"
cp "${built_file}" "${workspace}/output/${built_file_name}"
chmod 0644 "${workspace}/output/${built_file_name}"

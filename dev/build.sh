#!/usr/bin/env bash


# This script can be used to build the artifacts in a specified directory
# TODO: Can bazel do this directly in bazel targets?

set -o errexit -o nounset

workspace=$(bazel info workspace)

export KUBECF_CHART_TARGET="//deploy/helm/kubecf"
export KUBECF_BUNDLE_TARGET="//deploy/bundle:kubecf-bundle"
export KUBECF_VERSION_TARGET="//deploy/helm/kubecf:version"

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

OUTPUTDIR=${1:-output}
mkdir -p "${OUTPUTDIR}"

# Build the txt file that contains the chart verison.
bazel build "${KUBECF_VERSION_TARGET}"
built_file="$(get_output_file "${KUBECF_VERSION_TARGET%:*}" "txt")"
built_file_name="$(basename "${built_file}")"
version=$(cat "${built_file}")

# Build the kubecf helm chart
bazel build "${KUBECF_CHART_TARGET}"
built_file="$(get_output_file "${KUBECF_CHART_TARGET%:*}" "tgz")"
built_file_name="$(basename "${built_file}" .tgz)"
target_file="${workspace}/${OUTPUTDIR}/${built_file_name}-${version}.tgz"
cp "${built_file}" "${target_file}"
chmod 0644 "${target_file}"

# Build the install bundle (kubecf chart + cf-operator chart)
bazel build "${KUBECF_BUNDLE_TARGET}"
built_file="$(get_output_file "${KUBECF_BUNDLE_TARGET%:*}" "tgz")"
built_file_name="$(basename "${built_file}" .tgz)"
target_file="${workspace}/${OUTPUTDIR}/${built_file_name}-${version}.tgz"
cp "${built_file}" "${target_file}"
chmod 0644 "${target_file}"

# Make sure the build process didn't modify any files in the source tree.
if ! git diff-index --quiet HEAD; then
  >&2 echo "The build changed files in the source tree that should be committed or git-ignored."
  git status
  exit 1
fi

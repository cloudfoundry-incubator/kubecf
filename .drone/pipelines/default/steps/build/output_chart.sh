#!/usr/bin/env bash

set -o errexit -o nounset

workspace=$(bazel info workspace)

output_chart() {
  chart=("${workspace}/output"/kubecf-*.tgz)
  if [[ "${#chart[@]}" != "1" ]]; then
    >&2 echo "Failed to get single chart output, found ${#chart[@]} candidates"
    return 1
  fi
  echo "${chart[@]}"
}

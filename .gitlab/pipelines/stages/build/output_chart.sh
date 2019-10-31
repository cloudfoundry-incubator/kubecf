#!/usr/bin/env bash

set -o errexit -o nounset

output_chart() {
  chart=(output/kubecf-*.tgz)
  if [[ "${#chart[@]}" != "1" ]]; then
    >&2 echo "Failed to get single chart output, found ${#chart[@]} candidates"
    return 1
  fi
  echo "${chart[@]}"
}

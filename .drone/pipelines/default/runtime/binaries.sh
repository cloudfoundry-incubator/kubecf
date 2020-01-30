#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

path_sh="/tmp/path.sh"

if [[ ! -f "${path_sh}" ]]; then
  targets=()
  while IFS='' read -r target; do targets+=("${target}"); done < <(
    bazel query 'kind(binary_location, //:all)' 2> /dev/null
  )

  for target in "${targets[@]}"; do
    binary_location=$(bazel run "${target}")
    binary_dir=$(dirname "${binary_location}")
    PATH="${binary_dir}:${PATH}"
  done

  echo "export PATH=${PATH}" > "${path_sh}"
fi

# shellcheck disable=SC1090
source "${path_sh}"

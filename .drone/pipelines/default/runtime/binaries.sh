#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

targets=()
while IFS='' read -r target; do targets+=("${target}"); done < <(
  bazel query 'kind(binary_location, //rules/external_binary/...)' 2> /dev/null
)

for target in "${targets[@]}"; do
  binary_location=$(bazel run "${target}" 2> /dev/null)
  binary_name=$(basename "${binary_location}")
  binary_dir=$(dirname "${binary_location}")
  echo "Adding ${binary_name} to \$PATH..."
  PATH="${binary_dir}:${PATH}"
  export PATH
done

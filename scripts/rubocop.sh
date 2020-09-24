#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools rubocop

dirs=(
    chart/assets/scripts/
)

disabled_cops=(
    Metrics/BlockLength
)
disabled_cops_string="$(IFS=, ; echo "${disabled_cops[*]}")"

rubocop --except "${disabled_cops_string}" "${dirs[@]}"

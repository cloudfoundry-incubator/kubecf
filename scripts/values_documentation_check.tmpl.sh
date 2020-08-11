#!/usr/bin/env bash

# This script is used to run create_sample_values.rb in check mode.  This is
# necessary as (as far as I can tell) bazel tests _need_ to be implmented as a
# single executable containing all context.

set -o errexit -o nounset -o pipefail

test_script='[[test_script]]'
test_input='[[test_input]]'

export DEBUG=1
export MODE=CHECK
exec "${test_script}" "${test_input}"

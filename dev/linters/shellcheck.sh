#!/usr/bin/env bash

set -o errexit -o nounset

workspace=$(bazel info workspace)

find_args=(
    -not \( -path "${workspace}/deploy/helm/kubecf/charts" -prune \)
    -not \( -path "${workspace}/output" -prune \)
    -not \( -path "${workspace}/src" -prune \)
    -name '*.sh'
)

# shellcheck disable=SC2046
# We want word splitting with find.
#bazel run @shellcheck//:binary -- $(find "${workspace}" "${find_args[@]}")

# Bazel will run `shellcheck` inside the sandbox, but the files it checks are
# not copied inside. It passes all files to be checked by absolute filename
# via $workspace. That way relative filenames don't resolve and produce bogus
# errors. Workaround follows:

# Determine shellcheck version because it is part of the path inside the cache.
VERSION=$( < dependencies.yaml bazel run --experimental_ui_limit_console_output=1 @yq//:binary \
             -- read - binaries.shellcheck.version)

# Make sure shellcheck is downloaded into the Bazel cache.
bazel run @shellcheck//:binary -- --version &> /dev/null

# Call cached bazel binary of shellcheck from current directory manually.
# shellcheck disable=SC2046
# We want word splitting with find.
"./bazel-kubecf/external/shellcheck/shellcheck-v${VERSION}/shellcheck" \
    -- $(find "${workspace}" "${find_args[@]}")

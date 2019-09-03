#!/usr/bin/env bash

set -o errexit -o nounset

bazel build //deploy/helm/scf:chart
built_file="$(realpath bazel-bin/deploy/helm/scf/scf-*.tgz)"
mkdir -p output
cp "${built_file}" output/

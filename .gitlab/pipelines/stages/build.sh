#!/usr/bin/env bash

set -o errexit -o nounset

bazel build //deploy/helm/scf:chart
mkdir -p output; (cd bazel-bin/deploy/helm/scf; tar cf - scf-*.tgz) | (cd output; tar xvf -)

built_file="$(find output/ -name 'scf-*.tgz' -print0 | xargs -0 basename)"
commit_hash="$(git rev-parse --short HEAD)"
release_filename="$(basename "${built_file}" .tgz)-${commit_hash}"
if [ -n "$(git status --porcelain)" ]; then
  release_filename="${release_filename}-dirty"
fi

mv "output/${built_file}" "output/${release_filename}.tgz"

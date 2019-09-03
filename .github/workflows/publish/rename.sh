#!/usr/bin/env bash

set -o errexit -o nounset

built_file="$(ls output/scf-*.tgz)"
commit_hash="$(git rev-parse --short HEAD)"
release_filename="$(basename "${built_file}" .tgz)-${commit_hash}"
if [ ! -z "$(git status --porcelain)" ]; then
  release_filename="${release_filename}-dirty"
fi

mv "output/${built_file}" "output/${release_filename}.tgz"

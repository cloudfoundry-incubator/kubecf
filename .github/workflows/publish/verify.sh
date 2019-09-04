#!/usr/bin/env bash

set -o errexit -o nounset

if [[ "$(ls output/scf-*.tgz | wc -l)" != 1 ]]; then exit 1; fi

ls -lha output/scf-*.tgz
tar tvf output/scf-*.tgz

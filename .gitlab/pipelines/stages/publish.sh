#!/usr/bin/env bash

set -o errexit -o nounset

mc config host add "s3" "https://s3.amazonaws.com" "${AWS_ACCESS_KEY}" "${AWS_SECRET_KEY}"
mc cp output/scf-*.tgz "s3/scf-v3"
echo "URL: https://scf-v3.s3.amazonaws.com/$(find output/ -name 'scf-*.tgz' -print0 | xargs -0 basename)"

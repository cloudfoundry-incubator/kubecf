#!/bin/sh

set -o errexit -o nounset

alias="s3"

mc config host add "${alias}" "https://s3.amazonaws.com" "${AWS_ACCESS_KEY}" "${AWS_SECRET_KEY}"
mc cp output/scf-*.tgz "${alias}/${BUCKET}"
echo "URL: https://${BUCKET}.s3.amazonaws.com/$(find output/ -name 'scf-*.tgz' -print0 | xargs -0 basename)"

#!/bin/sh

set -o errexit -o nounset

mc config host add "s3" "https://s3.amazonaws.com" "${AWS_ACCESS_KEY}" "${AWS_SECRET_KEY}"
for file in output/kubecf-*.tgz ; do
    mc cp "${file}" "s3/scf-v3"
    echo "URL: https://scf-v3.s3.amazonaws.com/$(basename "${file}")"
done

#!/bin/sh

set -o errexit -o nounset

version=$(cat "output/version.txt")

if [ -z "${version}" ]; then
  >&2 echo "Version not set!"
  exit 1
fi

mc config host add "s3" "https://s3.amazonaws.com" "${AWS_ACCESS_KEY}" "${AWS_SECRET_KEY}"

mc cp "output/kubecf.tgz" "s3/scf-v3/kubecf-${version}.tgz"
echo "URL: https://scf-v3.s3.amazonaws.com/kubecf-${version}.tgz"

mc cp "output/kubecf.tgz" "s3/kubecf/kubecf-${version}.tgz"
echo "URL: https://kubecf.s3.amazonaws.com/kubecf-${version}.tgz"
mc cp "output/bundle.tgz" "s3/kubecf/bundle-${version}.tgz"
echo "URL: https://kubecf.s3.amazonaws.com/bundle-${version}.tgz"

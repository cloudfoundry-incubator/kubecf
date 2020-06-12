#!/usr/bin/env bash

set -o errexit -o nounset

if grep --exclude="helmlint.sh" --exclude-dir="./deploy/helm/kubecf/charts" -r "{{-.*-}}" .; then
    echo "Found double minus templates {{- ... -}}"
    exit 1
fi

exec bazel test //dev/linters:helm

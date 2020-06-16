#!/usr/bin/env bash

set -o errexit -o nounset

if git -c core.pager=cat grep '{{-.*-}}' -- . ':!/deploy/helm/kubecf/charts' ':!/dev/linters/helmlint.sh'; then
    echo "Found double minus templates {{- ... -}}"
    exit 1
fi

exec bazel test //dev/linters:helm

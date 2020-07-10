#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools git helm

cd deploy/helm/kubecf
rm -rf charts/*
helm dep up
for CHART in charts/*.tgz; do tar xfz "${CHART}" -C charts; rm "${CHART}"; done
git add --all .

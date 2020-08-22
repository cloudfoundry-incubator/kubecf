#!/usr/bin/env bash

set -e

cd chart
rm -rf charts/*
helm dep up
for CHART in charts/*.tgz; do tar xfz "${CHART}" -C charts; rm "${CHART}"; done
git add --all .

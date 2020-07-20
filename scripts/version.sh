#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools git

echo "${KUBECF_VERSION}-$(git rev-parse --short HEAD)"

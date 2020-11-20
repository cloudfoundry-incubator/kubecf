#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools helm kubectl

helm upgrade kubecf "${CHART}" \
     --namespace "${KUBECF_NS}" --values "${VALUES}" "$@"

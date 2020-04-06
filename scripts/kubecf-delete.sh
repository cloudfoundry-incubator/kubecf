#!/usr/bin/env bash
: "${GIT_ROOT:=$(git rev-parse --show-toplevel)}"
# shellcheck disable=SC1090
source "${GIT_ROOT}/scripts/include/setup.sh"

require_tools helm kubectl xargs_no_run_if_empty

helm delete kubecf --namespace "${KUBECF}"
kubectl get --namespace "${KUBECF_NS}" pvc --output name | \
    xargs_no_run_if_empty kubectl delete --namespace "${KUBECF_NS}"

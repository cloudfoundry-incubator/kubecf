#!/usr/bin/env bash
set -o errexit -o nounset
: "${GIT_ROOT:=$(git rev-parse --show-toplevel)}"
cd "${GIT_ROOT}"

NO_RUN_IF_EMPTY="--no-run-if-empty"
if [ "$(uname)" = "Darwin" ]; then
    NO_RUN_IF_EMPTY=""
fi

helm delete kubecf -n kubecf
kubectl get -n kubecf pvc -o name | xargs ${NO_RUN_IF_EMPTY} kubectl delete -n kubecf

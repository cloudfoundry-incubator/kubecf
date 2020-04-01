#!/usr/bin/env bash
set -o errexit -o nounset
: "${GIT_ROOT:=$(git rev-parse --show-toplevel)}"
cd "${GIT_ROOT}"

kubectl create ns cf-operator
helm install cf-operator $(cat cf-operator-url) \
     --namespace cf-operator \
     --set global.operator.watchNamespace=kubecf

#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools kubectl helm

kubectl create ns "${CF_OPERATOR_NS}"

helm install cf-operator "${CF_OPERATOR_URL}" \
     --namespace "${CF_OPERATOR_NS}" \
     --set "global.operator.watchNamespace=${KUBECF_NS}"

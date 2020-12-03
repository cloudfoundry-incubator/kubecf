#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools cf_operator_url kubectl helm

if ! kubectl get ns "${CF_OPERATOR_NS}" &> /dev/null; then
    kubectl create ns "${CF_OPERATOR_NS}" > /dev/null
fi

if [ -z "${CHART:-}" ]; then
    CHART="$(cf_operator_url)"
fi

helm upgrade cf-operator \
     "${CHART}" \
     --install \
     --namespace "${CF_OPERATOR_NS}" \
     --set "global.singleNamespace.name=${KUBECF_NS}" \
     ${VALUES:+--values "${VALUES}"} \
     "$@"

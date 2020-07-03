#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools kubectl helm

if ! kubectl get ns "${CF_OPERATOR_NS}" &> /dev/null; then
    kubectl create ns "${CF_OPERATOR_NS}" > /dev/null
fi

helm install cf-operator \
     "${CF_OPERATOR_URL//\{version\}/${CF_OPERATOR_VERSION}}" \
     --namespace "${CF_OPERATOR_NS}" \
     --set "global.singleNamespace.name=${KUBECF_NS}"

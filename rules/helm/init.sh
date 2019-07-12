#!/usr/bin/env bash

set -o errexit -o nounset

if ! "${KUBECTL}" get serviceaccount "${SERVICE_ACCOUNT}" --namespace kube-system 1> /dev/null 2> /dev/null; then
  "${KUBECTL}" create serviceaccount "${SERVICE_ACCOUNT}" \
    --namespace kube-system
  "${KUBECTL}" create clusterrolebinding "${SERVICE_ACCOUNT}" \
    --clusterrole cluster-admin \
    --serviceaccount=kube-system:"${SERVICE_ACCOUNT}"
fi

"${HELM}" init --upgrade --service-account "${SERVICE_ACCOUNT}"

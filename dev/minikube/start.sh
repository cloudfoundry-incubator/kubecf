#!/usr/bin/env bash

set -o errexit -o nounset

if ! "${MINIKUBE}" status > /dev/null; then
  "${MINIKUBE}" start \
    --kubernetes-version "${K8S_VERSION}" \
    --cpus "${VM_CPUS}" \
    --memory "${VM_MEMORY}" \
    --disk-size "${VM_DISK_SIZE}" \
    --iso-url "${ISO_URL}" \
    --extra-config=apiserver.enable-admission-plugins=MutatingAdmissionWebhook
else
  echo "Minikube is already started"
fi

"${HELM_INIT}"

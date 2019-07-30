#!/usr/bin/env bash

set -o errexit -o nounset

if ! "${MINIKUBE}" status > /dev/null; then
  "${MINIKUBE}" start \
    --kubernetes-version "${K8S_VERSION}" \
    --cpus "${VM_CPUS}" \
    --memory "${VM_MEMORY}" \
    --disk-size "${VM_DISK_SIZE}" \
    --iso-url "${ISO_URL}" \
    ${VM_DRIVER:+--vm-driver "${VM_DRIVER}"} \
    --extra-config=apiserver.enable-admission-plugins=MutatingAdmissionWebhook

  # Enable hairpin by setting the docker0 promiscuous mode on.
  "${MINIKUBE}" ssh -- "sudo ip link set docker0 promisc on"
else
  echo "Minikube is already started"
fi

"${HELM_INIT}"

#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools minikube

: "${K8S_VERSION:=1.15.6}"
: "${VM_CPUS:=4}"
: "${VM_MEMORY:=16384}"
: "${VM_DISK_SIZE:=120g}"

if ! minikube status > /dev/null; then
    # shellcheck disable=SC2086
    minikube start \
             --kubernetes-version "${K8S_VERSION}" \
             --cpus "${VM_CPUS}" \
             --memory "${VM_MEMORY}" \
             --disk-size "${VM_DISK_SIZE}" \
             --iso-url "${MINIKUBE_ISO_URL}" \
             ${VM_DRIVER:+--vm-driver "${VM_DRIVER}"} \
             --extra-config=apiserver.runtime-config=settings.k8s.io/v1alpha1=true \
             --extra-config=apiserver.enable-admission-plugins=MutatingAdmissionWebhook,PodPreset \
             ${MINIKUBE_EXTRA_OPTIONS:-}

    # Enable hairpin by setting the docker0 promiscuous mode on.
    minikube ssh -- "sudo ip link set docker0 promisc on"
else
    echo "Minikube is already started"
fi

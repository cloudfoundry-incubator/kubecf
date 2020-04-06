#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools minikube

# shellcheck disable=SC2034
MINIKUBE="minikube"
K8S_VERSION=${K8S_VERSION:-1.15.6}
VM_CPUS=${VM_CPUS:-4}
VM_MEMORY=${VM_MEMORY:-16384}
VM_DISK_SIZE=${VM_DISK_SIZE:-120g}
# shellcheck disable=SC2034
ISO_URL=${MINIKUBE_ISO_URL}

# shellcheck disable=SC1091
source ./dev/minikube/start.sh

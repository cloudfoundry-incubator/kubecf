#!/usr/bin/env bash
set -o errexit -o nounset
: "${GIT_ROOT:=$(git rev-parse --show-toplevel)}"
cd "${GIT_ROOT}"

export MINIKUBE=minikube
export K8S_VERSION=${K8S_VERSION:-1.15.6}
export VM_CPUS=${VM_CPUS:-4}
export VM_MEMORY=${VM_MEMORY:-16384}
export VM_DISK_SIZE=${VM_DISK_SIZE:-120g}
export ISO_URL=${ISO_URL:-https://github.com/f0rmiga/opensuse-minikube-image/releases/download/v0.1.6/minikube-openSUSE.x86_64-0.1.6.iso}

./dev/minikube/start.sh

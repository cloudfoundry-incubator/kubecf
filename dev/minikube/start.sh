#!/usr/bin/env bash

set -o errexit -o nounset

: "${K8S_VERSION:=v1.13.6}"
: "${VM_CPUS:=4}"
: "${VM_MEMORY:=$(( 1024 * 16 ))}"
: "${VM_DISK_SIZE:=120g}"

minikube start "${@}" \
  --kubernetes-version "${K8S_VERSION}" \
  --cpus "${VM_CPUS}" \
  --memory "${VM_MEMORY}" \
  --disk-size "${VM_DISK_SIZE}" \
  --extra-config=apiserver.enable-admission-plugins=MutatingAdmissionWebhook

helm init --upgrade --wait

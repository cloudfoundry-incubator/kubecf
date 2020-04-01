#!/usr/bin/env bash
set -o errexit -o nounset
: "${GIT_ROOT:=$(git rev-parse --show-toplevel)}"
cd "${GIT_ROOT}"

HELM_ARGS=()
for TEST in brain cf_acceptance smoke; do
    HELM_ARGS+=(--set testing.${TEST}_tests.enabled=true)
done

if [ "$(kubectl config current-context)" = "minikube" ]; then
    MINIKUBE_IP=$(minikube ip)
    HELM_ARGS+=(--set system_domain=${MINIKUBE_IP}.xip.io)
    for SERVICE in router tcp-router ssh-proxy; do
        HELM_ARGS+=(
            --set services.${SERVICE}.type=LoadBalancer
            --set services.${SERVICE}.externalIPs[0]=${MINIKUBE_IP}
        )
    done
fi

VERSION=${VERSION:-v0.0.0-$(git rev-parse --short HEAD)}
helm install kubecf --namespace kubecf output/kubecf-${VERSION}.tgz "${HELM_ARGS[@]}" "$@"

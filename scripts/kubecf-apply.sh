#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools helm kubectl

HELM_ARGS=()
for TEST in brain cf_acceptance smoke; do
    HELM_ARGS+=(--set "testing.${TEST}_tests.enabled=true")
done

if [ "$(kubectl config current-context)" = "minikube" ]; then
    require_tools minikube
    MINIKUBE_IP=$(minikube ip)
    HELM_ARGS+=(--set "system_domain=${MINIKUBE_IP}.xip.io")
    for SERVICE in router tcp-router ssh-proxy; do
        HELM_ARGS+=(
            --set "services.${SERVICE}.type=LoadBalancer"
            --set "services.${SERVICE}.externalIPs[0]=${MINIKUBE_IP}"
        )
    done
fi

VERSION=${VERSION:-v0.0.0-$(git rev-parse --short HEAD)}
helm upgrade kubecf "output/kubecf-${VERSION}.tgz" \
     --install --namespace "${KUBECF_NS}" "${HELM_ARGS[@]}" "$@"

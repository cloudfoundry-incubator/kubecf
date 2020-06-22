#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools helm kubectl

HELM_ARGS=()
for TEST in brain cf_acceptance smoke; do
    HELM_ARGS+=(--set "testing.${TEST}_tests.enabled=true")
done

if [ -z "${LOCAL_IP:-}" ]; then
    CONTEXT="$(kubectl config current-context)"
    if [ "${CONTEXT}" = "minikube" ]; then
        require_tools minikube
        LOCAL_IP=$(minikube ip)
    elif [[ "${CONTEXT}" =~ ^kind- ]]; then
        LOCAL_IP="$(kubectl get node ${CLUSTER_NAME}-control-plane \
         -o jsonpath='{ .status.addresses[?(@.type == "InternalIP")].address }')"
    fi
fi

if [ -n "${LOCAL_IP:-}" ]; then
    HELM_ARGS+=(--set "system_domain=${LOCAL_IP}.xip.io")
    for SERVICE in router tcp-router ssh-proxy; do
        HELM_ARGS+=(
            --set "services.${SERVICE}.type=LoadBalancer"
            --set "services.${SERVICE}.externalIPs[0]=${LOCAL_IP}"
        )
    done
fi

if [ -n "${FEATURE_AUTOSCALER:-}" ]; then
    HELM_ARGS+=(--set "features.autoscaler.enabled=true")
fi

if [ -n "${FEATURE_EIRINI:-}" ]; then
    HELM_ARGS+=(--set "features.eirini.enabled=true")
fi

if [ -n "${FEATURE_INGRESS:-}" ]; then
    HELM_ARGS+=(--set "features.ingress.enabled=true")
fi

if [ -n "${VALUES:-}" ]; then
    HELM_ARGS+=(--values "${VALUES}")
fi

VERSION=${VERSION:-v0.0.0-$(git rev-parse --short HEAD)}
helm upgrade kubecf "output/kubecf-${VERSION}.tgz" \
     --install --namespace "${KUBECF_NS}" "${HELM_ARGS[@]}" "$@"

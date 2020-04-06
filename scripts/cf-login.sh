#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools base64 cf kubectl

SYSTEM_DOMAIN=$(kubectl get secret --namespace "${KUBECF_NS}" kubecf.var-system-domain \
                        --output jsonpath='{.data.value}' | base64 --decode)

ADMIN_PASSWORD=$(kubectl get secret --namespace "${KUBECF_NS}" kubecf.var-cf-admin-password \
                         --output jsonpath='{.data.password}' | base64 --decode)

cf login --skip-ssl-validation -a "https://api.${SYSTEM_DOMAIN}" -u admin -p "${ADMIN_PASSWORD}"

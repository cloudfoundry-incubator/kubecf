#!/usr/bin/env bash

export KUBECF_NAMESPACE="kubecf"
export CF_OPERATOR_NAMESPACE="cfo"
export CLUSTER_IP="10.104.255.255"
export SYSTEM_DOMAIN="${CLUSTER_IP}.nip.io"
: "${EIRINI_ENABLED:=false}"
export EIRINI_ENABLED
export KUBECF_CHART_TARGET="//deploy/helm/kubecf:chart"
export BOSHDEPLOYMENT_CRD="boshdeployments.fissile.cloudfoundry.org"

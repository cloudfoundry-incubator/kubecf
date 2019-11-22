#!/usr/bin/env bash

export KUBECF_NAMESPACE="kubecf"
export CF_OPERATOR_NAMESPACE="cfo"
export ROUTER_CLUSTER_IP="10.43.0.250"
export SSH_PROXY_CLUSTER_IP="10.43.0.251"
export SYSTEM_DOMAIN="kubecf-ci.susecap.net"
: "${EIRINI_ENABLED:=false}"
export EIRINI_ENABLED
export KUBECF_CHART_TARGET="//deploy/helm/kubecf:chart"
export BOSHDEPLOYMENT_CRD="boshdeployments.quarks.cloudfoundry.org"

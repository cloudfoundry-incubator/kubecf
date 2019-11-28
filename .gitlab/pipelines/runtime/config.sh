#!/usr/bin/env bash

export KUBECF_NAMESPACE="kubecf"
export CF_OPERATOR_NAMESPACE="cfo"
export ROUTER_CLUSTER_IP="10.43.0.231"
export SSH_PROXY_CLUSTER_IP="10.43.0.232"
export SYSTEM_DOMAIN="k3s-ci.kubecf.aws.howdoi.website"
: "${EIRINI_ENABLED:=false}"
export EIRINI_ENABLED
export KUBECF_CHART_TARGET="//deploy/helm/kubecf:chart"
export BOSHDEPLOYMENT_CRD="boshdeployments.quarks.cloudfoundry.org"
export CATS_INCLUDE="+tcp_routing"

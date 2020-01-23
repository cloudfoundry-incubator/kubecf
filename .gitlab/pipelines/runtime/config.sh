#!/usr/bin/env bash

export KUBECF_INSTALL_NAME="kubecf"
export KUBECF_NAMESPACE="kubecf"
export CF_OPERATOR_NAMESPACE="kubecf"
export ROUTER_CLUSTER_IP="10.43.0.231"
export SSH_PROXY_CLUSTER_IP="10.43.0.232"
export TCP_ROUTER_CLUSTER_IP="10.43.0.233"
export SYSTEM_DOMAIN="k3s-ci.kubecf.aws.howdoi.website"
: "${EIRINI_ENABLED:=false}"
export EIRINI_ENABLED
export KUBECF_CHART_TARGET="//deploy/helm/kubecf"
export KUBECF_BUNDLE_TARGET="//deploy/bundle:kubecf-bundle"
export BOSHDEPLOYMENT_CRD="boshdeployments.quarks.cloudfoundry.org"

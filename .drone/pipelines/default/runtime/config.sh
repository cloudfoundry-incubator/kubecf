#!/usr/bin/env bash

export CLUSTER_NAME="kubecf-drone-ci"
export KUBECF_INSTALL_NAME="kubecf"
export KUBECF_NAMESPACE="kubecf"
export CF_OPERATOR_NAMESPACE="kubecf"
: "${EIRINI_ENABLED:=false}"
export EIRINI_ENABLED
export KUBECF_CHART_TARGET="//deploy/helm/kubecf"
export KUBECF_BUNDLE_TARGET="//deploy/bundle:kubecf-bundle"

#!/usr/bin/env bash

export KUBECF_INSTALL_NAME="kubecf"
export KUBECF_NAMESPACE="kubecf"
export CF_OPERATOR_NAMESPACE="cfo"
: "${EIRINI_ENABLED:=false}"
export EIRINI_ENABLED
export KUBECF_CHART_TARGET="//deploy/helm/kubecf:chart"
export KUBECF_BUNDLE_TARGET="//deploy/bundle:kubecf-bundle"

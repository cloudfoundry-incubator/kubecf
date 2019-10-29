#!/usr/bin/env bash

export KUBECF_NAMESPACE="kubecf"
export CLUSTER_IP="10.104.255.255"
export SYSTEM_DOMAIN="${CLUSTER_IP}.nip.io"
: "${EIRINI_ENABLED:=false}"
export EIRINI_ENABLED
# TODO: Read from the def.bzl once it's implemented there.
: "${CF_OPERATOR_CHART_URL:=https://s3.amazonaws.com/cf-operators/helm-charts/cf-operator-v0.4.2%2B85.gc6d71da5.tgz}"
export CF_OPERATOR_CHART_URL
export KUBECF_CHART_TARGET="//deploy/helm/scf:chart"
export BOSHDEPLOYMENT_CRD="boshdeployments.fissile.cloudfoundry.org"

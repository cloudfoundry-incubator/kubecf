#!/bin/bash

set -e

echo "Running the upgrade test"

KUBECF_LATEST_RELEASE=$(cat kubecf-github-release/version)
export KUBECF_LATEST_RELEASE
export SCF_CHART="https://github.com/cloudfoundry-incubator/kubecf/releases/download/v${KUBECF_LATEST_RELEASE}/kubecf-bundle-v${KUBECF_LATEST_RELEASE}.tgz"

export ENABLE_EIRINI=false
export SCF_OPERATOR=true

export FORCE_DELETE=true
export HELM_VERSION="v3.1.1"
export BACKEND=imported
export QUIET_OUTPUT=true
CLUSTER_NAME="$(cat kind-environments/name)"
export CLUSTER_NAME
KUBECFG="$(readlink -f kind-environments/metadata)"
export KUBECFG

pushd catapult
# Bring up a k8s cluster and builds+deploy kubecf
# https://github.com/SUSE/catapult/wiki/Build-and-run-SCF#build-and-run-kubecf
make kubeconfig scf

# Now upgrade to whatever chart we built for commit-to-test
# The chart should be in s3.kubecf-ci directory
SCF_CHART="$(readlink -f ../s3.kubecf-ci/*.tgz)"
export SCF_CHART
make scf-chart scf-upgrade

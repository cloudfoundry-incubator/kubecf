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
export GKE_CLUSTER_NAME="kubecf-ci-$(cat semver.gke-cluster/version)"
export KUBECFG="$(readlink -f ~/.kube/config)"

printf "%s" '((gke-suse-cap-json))' > $PWD/gke-key.json
export GKE_CREDS_JSON=$PWD/gke-key.json
export GKE_PROJECT={{ if has . "gke_project" }}{{ .gke_project }}{{ else }}"suse-225215"{{ end }}
export GKE_ZONE={{ if has . "gke_zone" }}{{ .gke_zone }}{{ else }}"europe-west3-c"{{ end }}

pushd catapult
# Bring up a k8s cluster and builds+deploy kubecf
# https://github.com/SUSE/catapult/wiki/Build-and-run-SCF#build-and-run-kubecf
make kubeconfig scf

# Now upgrade to whatever chart we built for commit-to-test
# The chart should be in s3.kubecf-ci directory
SCF_CHART="$(readlink -f ../s3.kubecf-ci/*.tgz)"
export SCF_CHART
make scf-chart scf-upgrade

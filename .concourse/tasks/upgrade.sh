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
GKE_CLUSTER_NAME="kubecf-ci-$(sed 'y/./-/' "semver.gke-cluster/version")"
export GKE_CLUSTER_NAME
KUBECFG="$(readlink --canonicalize ~/.kube/config)"
export KUBECFG

printf "%s" '((gke-suse-cap-json))' > "${PWD}/gke-key.json"
export GKE_CRED_JSON=$PWD/gke-key.json
gcloud auth activate-service-account --key-file "${PWD}/gke-key.json"

export GKE_PROJECT='{{ .gke_project | default "suse-225215" }}'
export GKE_ZONE='{{ .gke_zone | default "europe-west3-c"}}'

gcloud --quiet beta container \
  --project "${GKE_PROJECT}" clusters create "${GKE_CLUSTER_NAME}" \
  --zone "${GKE_ZONE}" \
  --no-enable-basic-auth \
  --machine-type "n1-highcpu-16" \
  --image-type "UBUNTU" \
  --disk-type "pd-ssd" \
  --disk-size "100" \
  --metadata disable-legacy-endpoints=true \
  --scopes "https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append" \
  --preemptible \
  --num-nodes "1" \
  --enable-stackdriver-kubernetes \
  --enable-ip-alias \
  --network "projects/${GKE_PROJECT}/global/networks/default" \
  --subnetwork "projects/${GKE_PROJECT}/regions/${GKE_ZONE%-?}/subnetworks/default" \
  --default-max-pods-per-node "110" \
  --no-enable-master-authorized-networks \
  --addons HorizontalPodAutoscaling,HttpLoadBalancing \
  --no-enable-autorepair

# Get a kubeconfig
gcloud container clusters get-credentials "${GKE_CLUSTER_NAME}" --zone "${GKE_CLUSTER_ZONE}" --project "${GKE_PROJECT}"

# https://unix.stackexchange.com/a/265151
read -r -d '' CONFIG_OVERRIDE <<'EOF' || true
sizing:
  diego_cell:
  ephemeral_disk:
    size: 300000
EOF
export CONFIG_OVERRIDE

pushd catapult
# Bring up a k8s cluster and builds+deploy kubecf
# https://github.com/SUSE/catapult/wiki/Build-and-run-SCF#build-and-run-kubecf
make kubeconfig scf

# Now upgrade to whatever chart we built for commit-to-test
# The chart should be in s3.kubecf-ci directory
SCF_CHART="$(readlink -f ../s3.kubecf-ci/*.tgz)"
export SCF_CHART
make scf-chart scf-upgrade

#!/bin/bash

# Notes
# - Parameters:
#   - GKE_KEY
#   - GKE_PROJECT
#   - GKE_ZONE
#   - GKE_DNS_ZONE
#   - GKE_DOMAIN
#
# - Variables used by catapult:
#   - GKE_CLUSTER_NAME
#   - GKE_CLUSTER_ZONE
#   - GKE_CRED_JSON
#   - GKE_PROJECT
#
#   - BACKEND
#   - CONFIG_OVERRIDE
#   - KUBECFG
#   - DOWNLOAD_CATAPULT_DEPS=false
#   - QUIET_OUTPUT
#   - SCF_CHART
#
# Variables used by kubectl, gcloud, ...
#   - KUBECONFIG

set -o errexit

echo "Running the upgrade test"

# Fail early for missing parameters
: "${GKE_KEY:?}"
: "${GKE_PROJECT:?}"
: "${GKE_ZONE:?}"
: "${GKE_DNS_ZONE:?}"
: "${GKE_DOMAIN:?}"

export GKE_CLUSTER_ZONE="$GKE_ZONE"

KUBECF_LATEST_RELEASE="$(cat kubecf-github-release/version)"
export KUBECF_LATEST_RELEASE
export SCF_CHART="https://github.com/cloudfoundry-incubator/kubecf/releases/download/v${KUBECF_LATEST_RELEASE}/kubecf-bundle-v${KUBECF_LATEST_RELEASE}.tgz"
export ENABLE_EIRINI=false

export BACKEND=gke
export DOWNLOAD_CATAPULT_DEPS=false
export QUIET_OUTPUT=true

GKE_CLUSTER_NAME="${RESOURCE_PREFIX}-${BRANCH//./-}-upgrade-$(sed 'y/./-/' "semver.gke-cluster/version")"
export GKE_CLUSTER_NAME
KUBECONFIG="$(readlink --canonicalize "${PWD}/kubeconfig")"
export KUBECONFIG

# log into the project
printf "%s" "${GKE_KEY}" > "${PWD}/gke-key.json"
export GKE_CRED_JSON="${PWD}/gke-key.json"
gcloud auth activate-service-account --key-file "${PWD}/gke-key.json"

export DOMAIN="${GKE_CLUSTER_NAME}.${GKE_DOMAIN}"

# create the cluster to test with
gcloud --quiet beta container \
  --project "${GKE_PROJECT}" clusters create "${GKE_CLUSTER_NAME}" \
  --zone "${GKE_CLUSTER_ZONE}" \
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
  --subnetwork "projects/${GKE_PROJECT}/regions/${GKE_CLUSTER_ZONE%-?}/subnetworks/default" \
  --default-max-pods-per-node "110" \
  --no-enable-master-authorized-networks \
  --addons HorizontalPodAutoscaling,HttpLoadBalancing \
  --no-enable-autorepair \
  --no-enable-autoupgrade \
  --no-enable-autoprovisioning

# Get a kubeconfig - Placed into KUBECONFIG
gcloud container clusters get-credentials "${GKE_CLUSTER_NAME}" --zone "${GKE_CLUSTER_ZONE}" --project "${GKE_PROJECT}"

# https://unix.stackexchange.com/a/265151
read -r -d '' CONFIG_OVERRIDE <<'EOF' || true
sizing:
  diego_cell:
    ephemeral_disk:
      size: 40000
EOF
export CONFIG_OVERRIDE

export KUBECFG="${KUBECONFIG}"

pushd catapult
CLUSTER_PASSWORD=$(tr -dc 'a-zA-Z0-9' < /dev/random | fold -w 32 | head -n 1)
export CLUSTER_PASSWORD
# Import k8s cluster
make kubeconfig
# Deploy kubecf from public GH release
make kubecf

# Setup dns
tcp_router_ip=$(kubectl get svc -n scf tcp-router-public -o json | jq -r .status.loadBalancer.ingress[].ip | head -n 1)
public_router_ip=$(kubectl get svc -n scf router-public -o json | jq -r .status.loadBalancer.ingress[].ip | head -n 1)

gcloud --quiet beta dns --project="${GKE_PROJECT}" record-sets transaction start \
       --zone="${GKE_DNS_ZONE}"
gcloud --quiet beta dns --project="${GKE_PROJECT}" record-sets transaction add \
       --name="*.${DOMAIN}." --ttl=300 --type=A --zone="${GKE_DNS_ZONE}" "$public_router_ip"
gcloud --quiet beta dns --project="${GKE_PROJECT}" record-sets transaction add \
       --name="tcp.${DOMAIN}." --ttl=300 --type=A --zone="${GKE_DNS_ZONE}" "${tcp_router_ip}"
gcloud --quiet beta dns --project="${GKE_PROJECT}" record-sets transaction execute \
       --zone="${GKE_DNS_ZONE}"

# Now upgrade to whatever chart we built for commit-to-test
# The chart should be in s3.kubecf-ci-bundle directory
SCF_CHART="$(readlink -f ../s3.kubecf-ci-bundle/*.tgz)"
export SCF_CHART

make kubecf-chart
make kubecf-upgrade
KUBECF_TEST_SUITE=smokes make tests-kubecf

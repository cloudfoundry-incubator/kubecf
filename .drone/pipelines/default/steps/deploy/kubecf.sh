#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

# shellcheck disable=SC1091
source ".drone/pipelines/default/runtime/binaries.sh"
# shellcheck disable=SC1091
source ".drone/pipelines/default/runtime/config.sh"

node_ip=$(kubectl get node kubecf-control-plane \
  --output jsonpath='{ .status.addresses[?(@.type == "InternalIP")].address }')
system_domain="${node_ip}.nip.io"

chart="output/kubecf.tgz"

# Install the KubeCF chart.
helm upgrade "${KUBECF_INSTALL_NAME}" "${chart}" \
  --install \
  --namespace "${KUBECF_NAMESPACE}" \
  --values <(cat <<EOF
system_domain: "${system_domain}"

services:
  router:
    externalIPs:
    - ${node_ip}
  ssh-proxy:
    externalIPs:
    - ${node_ip}
  tcp-router:
    externalIPs:
    - ${node_ip}

features:
  eirini:
    enabled: ${EIRINI_ENABLED}

properties:
  acceptance-tests:
    acceptance-tests:
      acceptance_tests:
        ginkgo:
          slow_spec_threshold: 300
          nodes: 2

testing:
  cf_acceptance_tests:
    enabled: true
  smoke_tests:
    enabled: true

kube:
  service_cluster_ip_range: 0.0.0.0/0
  pod_cluster_ip_range: 0.0.0.0/0
EOF
)

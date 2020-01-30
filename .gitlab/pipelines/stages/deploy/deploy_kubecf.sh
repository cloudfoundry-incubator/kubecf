#!/usr/bin/env bash

set -o errexit -o nounset

workspace=$(bazel info workspace)

# shellcheck disable=SC1090
source "${workspace}/.gitlab/pipelines/runtime/config.sh"
# shellcheck disable=SC1090
source "${workspace}/.gitlab/pipelines/runtime/binaries.sh"

# Create a values.yaml for the test.
values="$(mktemp -t values_XXXXXXXX.yaml)"
cat > "${values}" <<EOF
system_domain: "${SYSTEM_DOMAIN}"

services:
  router:
    type: ClusterIP
    clusterIP: ${ROUTER_CLUSTER_IP}
  ssh-proxy:
    type: ClusterIP
    clusterIP: ${SSH_PROXY_CLUSTER_IP}
  tcp-router:
    type: ClusterIP
    clusterIP: ${TCP_ROUTER_CLUSTER_IP}

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
EOF

chart="${workspace}/output/kubecf.tgz"

# Install the KubeCF chart.
bazel run @helm//:binary -- \
  upgrade "${KUBECF_INSTALL_NAME}" "${chart}" \
  --install \
  --namespace "${KUBECF_NAMESPACE}" \
  --values "${values}"

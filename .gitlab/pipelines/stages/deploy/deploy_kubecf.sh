#!/usr/bin/env bash

set -o errexit -o nounset

# shellcheck disable=SC1090
source "$(bazel info workspace)/.gitlab/pipelines/runtime/config.sh"
# shellcheck disable=SC1090
source "$(bazel info workspace)/.gitlab/pipelines/runtime/binaries.sh"
# shellcheck disable=SC1090
source "$(bazel info workspace)/.gitlab/pipelines/stages/build/output_chart.sh"

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

features:
  eirini:
    enabled: ${EIRINI_ENABLED}

properties:
  acceptance-tests:
    acceptance-tests:
      acceptance_tests:
        include: '${CATS_INCLUDE}'
      ginkgo:
        slow_spec_threshold: 300
EOF

# Locate the built kubecf chart.
chart="$(output_chart)"

# Render and apply the kubecf chart.
bazel run @helm//:helm -- template "${chart}" --name "${KUBECF_INSTALL_NAME}" --namespace "${KUBECF_NAMESPACE}" --values "${values}" | "${KUBECTL}" apply -f -

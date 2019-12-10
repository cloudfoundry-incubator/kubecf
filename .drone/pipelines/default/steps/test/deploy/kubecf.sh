#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

workspace=$(bazel info workspace)

# shellcheck disable=SC1090
source "${workspace}/.drone/pipelines/default/steps/build/output_chart.sh"

node_ip=$(kubectl get node kubecf-control-plane \
  --output jsonpath='{ .status.addresses[?(@.type == "InternalIP")].address }')
system_domain="${node_ip}.nip.io"

# Create a values.yaml for the test.
values="$(mktemp -t values_XXXXXXXX.yaml)"
cat > "${values}" <<EOF
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
EOF

# Locate the built kubecf chart.
chart="$(output_chart)"

# Render and apply the kubecf chart.
helm template "${chart}" --name "${KUBECF_INSTALL_NAME}" --namespace "${KUBECF_NAMESPACE}" --values "${values}" \
  | kubectl apply -f -

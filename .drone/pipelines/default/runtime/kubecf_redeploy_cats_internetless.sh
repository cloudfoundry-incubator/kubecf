#!/usr/bin/env bash

# Variant of the deploy/kubecf.sh modified for changing the suites
# used by cats. In the future see to consolidation with the original
# and use parameters, templating, etc. to switch the modes.

set -o errexit -o nounset -o pipefail

# shellcheck disable=SC1091
source ".drone/pipelines/default/runtime/binaries.sh"
# shellcheck disable=SC1091
source ".drone/pipelines/default/runtime/config.sh"
# shellcheck disable=SC1091
source ".drone/pipelines/default/steps/build/output_chart.sh"
# shellcheck disable=SC1091
source ".drone/pipelines/default/runtime/cats_common.sh"

# shellcheck disable=SC2005
echo "$(blue "Configure CATS: =internetless")"

node_ip=$(kubectl get node kubecf-control-plane \
		  --output jsonpath='{ .status.addresses[?(@.type == "InternalIP")].address }')
system_domain="${node_ip}.nip.io"

# Locate thebuilt kubecf chart.
chart="$(output_chart)"

{
# Render and apply the kubecf chart.
helm template "${chart}" \
  --name "${KUBECF_INSTALL_NAME}" \
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
        # disable credhub tests, not controlled by property 'include'
        credhub_mode:   "off"
        ginkgo:
          slow_spec_threshold: 300
          nodes: 2
        include: "=internetless"

testing:
  cf_acceptance_tests:
    enabled: true
  smoke_tests:
    enabled: true

kube:
  service_cluster_ip_range: 0.0.0.0/0
  pod_cluster_ip_range: 0.0.0.0/0
EOF
) \
    | tee CHART | kubectl apply -f - \
    >& /dev/null
} || true

# tee CHART inserted for debugging, i.e. when we have to know the
# intermediate data, the applied chart itself.

wait_for_ig_job || exit 1
exit 0

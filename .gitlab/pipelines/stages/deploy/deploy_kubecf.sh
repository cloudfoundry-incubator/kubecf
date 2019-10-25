#!/usr/bin/env bash

set -o errexit -o nounset

# shellcheck disable=SC1090
source "$(bazel info workspace)/.gitlab/pipelines/config/config.sh"

# Locate the built kubecf chart.
chart="$(find output/ -name 'scf-*.tgz')"

# Create a values.yaml for the test.
values="$(mktemp -t values_XXXXXXXX.yaml)"
(cat <<EOF
system_domain: "${SYSTEM_DOMAIN}"

service:
  type: ClusterIP
  clusterIP: "${CLUSTER_IP}"

features:
  eirini:
    enabled: ${EIRINI_ENABLED}
EOF
) > "${values}"

# Render and apply the kubecf chart.
bazel run @helm//:helm -- template "${chart}" --name kubecf --namespace "${KUBECF_NAMESPACE}" --values "${values}" | bazel run @kubectl//:kubectl -- apply -f - --namespace "${KUBECF_NAMESPACE}"

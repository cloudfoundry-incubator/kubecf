#!/usr/bin/env bash

set -o errexit -o nounset

"${HELM}" template "${@}" \
  --name "${INSTALL_NAME}" \
  --namespace "${NAMESPACE}" \
  "${CHART_PACKAGE}" > "${OUTPUT_YAML}"

#!/usr/bin/env bash

set -o errexit -o nounset

"${HELM}" template "${INSTALL_NAME}" "${@:+$@}" \
  --namespace "${NAMESPACE}" \
  "${CHART_PACKAGE}" > "${OUTPUT_YAML}"

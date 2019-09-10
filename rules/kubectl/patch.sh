#!/usr/bin/env bash

set -o errexit -o nounset -o xtrace

"${KUBECTL}" patch "${RESOURCE_TYPE}" "${RESOURCE_NAME}" \
  --namespace "${NAMESPACE}" \
  --type "${PATCH_TYPE}" \
  --patch "$(cat "${PATCH_FILE}")"

#!/usr/bin/env bash

set -o errexit -o nounset

"${KUBECTL}" apply \
  --filename "${RESOURCE}" \
  ${NAMESPACE:+--namespace "${NAMESPACE}"}

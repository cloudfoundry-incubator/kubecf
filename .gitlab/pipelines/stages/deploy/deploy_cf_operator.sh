#!/usr/bin/env bash

set -o errexit -o nounset

# shellcheck disable=SC1090
source "$(bazel info workspace)/.gitlab/pipelines/config/config.sh"

# Install cf-operator.
chart="$(mktemp -t cf_operator_XXXXXXXX.tgz)"
curl -L -o "${chart}" "${CF_OPERATOR_CHART_URL}"
bazel run @helm//:helm -- template "${chart}" --name cf-operator --namespace "${KUBECF_NAMESPACE}" | bazel run @kubectl//:kubectl -- apply -f - --namespace "${KUBECF_NAMESPACE}"

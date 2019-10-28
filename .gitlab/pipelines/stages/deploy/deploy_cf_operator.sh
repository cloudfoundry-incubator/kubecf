#!/usr/bin/env bash

set -o errexit -o nounset

# shellcheck disable=SC1090
source "$(bazel info workspace)/.gitlab/pipelines/config/config.sh"

# Install cf-operator.
chart="$(mktemp -t cf_operator_XXXXXXXX.tgz)"
# TODO: switch to wget --tries=0 (to resume broken downloads in case of network error) once wget is
# available in the docker image.
curl -L -o "${chart}" "${CF_OPERATOR_CHART_URL}"
bazel run @helm//:helm -- template "${chart}" --name cf-operator --namespace "${KUBECF_NAMESPACE}" | bazel run @kubectl//:kubectl -- apply -f - --namespace "${KUBECF_NAMESPACE}"

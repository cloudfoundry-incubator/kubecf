#!/usr/bin/env bash
set -o errexit -o nounset
: "${GIT_ROOT:=$(git rev-parse --show-toplevel)}"
cd "${GIT_ROOT}"

kubectl patch qjob kubecf-smoke-tests --namespace kubecf --type merge \
        --patch '{"spec": {"trigger": {"strategy": "now"}}}'

# XXX wait until container is running

# kubectl logs --follow --namespace kubecf \
#        --selector "quarks.cloudfoundry.org/qjob-name in (kubecf-smoke-tests)" \
#        --container smoke-tests-smoke-tests

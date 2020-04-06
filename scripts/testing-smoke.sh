#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools kubectl

kubectl patch qjob kubecf-smoke-tests --namespace "${KUBECF_NS}" --type merge \
        --patch '{"spec": {"trigger": {"strategy": "now"}}}'

# XXX wait until container is running

# kubectl logs --follow --namespace kubecf \
#        --selector "quarks.cloudfoundry.org/qjob-name in (kubecf-smoke-tests)" \
#        --container smoke-tests-smoke-tests

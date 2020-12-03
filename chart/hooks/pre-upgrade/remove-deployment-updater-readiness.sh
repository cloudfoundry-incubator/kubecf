#!/bin/bash
set -o errexit -o nounset -o pipefail -o xtrace

# Remove the cc-deployment-updater readiness probes; they are incorrectly
# constructed for an active/passive job, and cause the scheduler to show as
# unready, and therefore blocking upgrades. See 
# https://github.com/cloudfoundry-incubator/kubecf/issues/1589 for details.

# Patch the StatefulSet so that any new instances we create will not have the
# probe.

patch='
---
spec:
  template:
    spec:
      containers:
      - name: cc-deployment-updater-cc-deployment-updater
        readinessProbe: ~
'

kubectl patch statefulset --namespace "$NAMESPACE" scheduler --patch "$patch"

# Delete all existing scheduler pods; we can't just patch them as changing
# existing readiness probes is not allowed.

mapfile -t pods < <(kubectl get pods --namespace="${NAMESPACE}" --output=name \
    --selector "quarks.cloudfoundry.org/instance-group-name=scheduler")

query='{.spec.containers[?(.name == "cc-deployment-updater-cc-deployment-updater")].readinessProbe.exec.command}'

for pod in "${pods[@]}"; do
    probe="$(kubectl get --namespace="${NAMESPACE}" "${pod}" --output=jsonpath="${query}")"
    if [[ -n "${probe}" ]]; then
        kubectl delete --namespace="${NAMESPACE}" "${pod}"
    fi
done

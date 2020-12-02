#!/bin/bash
set -o errexit -o nounset -o pipefail -o xtrace

# Remove the cc-deployment-updater readiness probes; they are incorrectly
# constructed for an active/passive job, and cause the scheduler to show as
# unready, and therefore blocking upgrades. See 
# https://github.com/cloudfoundry-incubator/kubecf/issues/1589 for details.

# Patch the StatefulSet so that any new instances we create will not have the
# probe.

# shellcheck disable=SC2016
patch='
---
spec:
  template:
    spec:
      containers:
      - name: cc-deployment-updater-cc-deployment-updater
        readinessProbe:
          $patch: delete
'

kubectl patch statefulset --namespace "$NAMESPACE" scheduler --patch "$patch"

# Delete all existing scheduler pods; we can't just patch them as changing
# existing readiness probes is not allowed.

kubectl delete pods --namespace="${NAMESPACE}" \
  --selector "quarks.cloudfoundry.org/instance-group-name=scheduler"

#!/bin/bash
set -ex

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

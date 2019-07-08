#!/usr/bin/env bash

set -o errexit -o nounset

helm upgrade scf deploy/helm/scf/scf-3.0.0.tgz \
    --install \
    --namespace scf \
    --values ./dev/scf/values.yaml

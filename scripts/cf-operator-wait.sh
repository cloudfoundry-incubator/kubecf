#!/usr/bin/env bash

# This script waits untils the operator is ready

source scripts/include/setup.sh

require_tools kubectl retry

# Wait for CRDs to show up
crds=(
    boshdeployments.quarks.cloudfoundry.org
    quarksjobs.quarks.cloudfoundry.org
    quarkssecrets.quarks.cloudfoundry.org
    quarksstatefulsets.quarks.cloudfoundry.org
)
for crd in "${crds[@]}" ; do
    RETRIES=60 DELAY=5 retry kubectl wait --for=condition=Established \
        "customresourcedefinition.apiextensions.k8s.io/${crd}"
done

# Wait for the operator deployments to be ready
deployments=( cf-operator cf-operator-quarks-job )
for deployment in "${deployments[@]}" ; do
    RETRIES=60 DELAY=5 retry kubectl wait --for=condition=Available \
        --namespace=cf-operator --timeout=600s "deployment/${deployment}"
done

#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools kubectl helm

set +e

helm delete cf-operator
kubectl delete ns "${CF_OPERATOR_NS}"
kubectl delete clusterrole cf-operator-quarks-job-cluster
kubectl delete clusterrole cf-operator-cluster
kubectl delete clusterrolebinding cf-operator-quarks-job-cluster
kubectl delete clusterrolebinding cf-operator-cluster
kubectl delete crd boshdeployments.quarks.cloudfoundry.org
kubectl delete crd quarksjobs.quarks.cloudfoundry.org
kubectl delete crd quarkssecrets.quarks.cloudfoundry.org
kubectl delete crd quarksstatefulsets.quarks.cloudfoundry.org

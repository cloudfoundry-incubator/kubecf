#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools kubectl helm

if helm ls --namespace "${CF_OPERATOR_NS}" 2>/dev/null | grep -qi "${CF_OPERATOR_RELEASE}" ; then
    helm delete "${CF_OPERATOR_RELEASE}" --namespace "${CF_OPERATOR_NS}"
fi

kubectl delete --ignore-not-found ns "${CF_OPERATOR_NS}"
kubectl delete --ignore-not-found clusterrole cf-operator-quarks-job-cluster
kubectl delete --ignore-not-found clusterrole cf-operator-cluster
kubectl delete --ignore-not-found clusterrolebinding cf-operator-quarks-job-cluster
kubectl delete --ignore-not-found clusterrolebinding cf-operator-cluster
kubectl delete --ignore-not-found crd boshdeployments.quarks.cloudfoundry.org
kubectl delete --ignore-not-found crd quarksjobs.quarks.cloudfoundry.org
kubectl delete --ignore-not-found crd quarkssecrets.quarks.cloudfoundry.org
kubectl delete --ignore-not-found crd quarksstatefulsets.quarks.cloudfoundry.org

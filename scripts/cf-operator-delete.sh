#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools kubectl helm

if helm ls --namespace "${CF_OPERATOR_NS}" 2>/dev/null | grep -qi "${CF_OPERATOR_RELEASE}" ; then
    helm delete "${CF_OPERATOR_RELEASE}" --namespace "${CF_OPERATOR_NS}"
fi

kubectl delete --ignore-not-found ns "${CF_OPERATOR_NS}"
for KIND in cluster job secret statefulset; do
    # The cluster role prefix may change from the release name to the namespace in the future:
    # https://github.com/cloudfoundry-incubator/quarks-operator/issues/1257
    kubectl delete --ignore-not-found clusterrole "${CF_OPERATOR_RELEASE}-quarks-${KIND}"
    kubectl delete --ignore-not-found clusterrolebinding "${CF_OPERATOR_RELEASE}-quarks-${KIND}"
done

kubectl delete --ignore-not-found crd boshdeployments.quarks.cloudfoundry.org
kubectl delete --ignore-not-found crd quarksjobs.quarks.cloudfoundry.org
kubectl delete --ignore-not-found crd quarkssecrets.quarks.cloudfoundry.org
kubectl delete --ignore-not-found crd quarksstatefulsets.quarks.cloudfoundry.org

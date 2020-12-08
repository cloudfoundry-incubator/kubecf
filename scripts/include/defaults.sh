# shellcheck shell=bash

: "${CF_OPERATOR_NS:=cf-operator}"
: "${KUBECF_NS:=kubecf}"

# Sometimes the helm release name is different from the namespace
# e.g. Catapult installs quarks-operator into a cfo namescace
# but still calls it cf-operator.
: "${CF_OPERATOR_RELEASE:=${CF_OPERATOR_NS}}"
: "${KUBECF_RELEASE:=${KUBECF_NS}}"

# Used by kind
: "${CLUSTER_NAME:=kubecf}"

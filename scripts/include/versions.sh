# shellcheck shell=bash

# Used by both kind-start and minikube-start
: "${K8S_VERSION:=1.17.5}"

: "${CF_OPERATOR_URL:=https://s3.amazonaws.com/cf-operators/release/helm-charts/cf-operator-{version\}.tgz}"
: "${CF_OPERATOR_SHA256:=df225af203596ca6dc11131004704632c01579bbaf80f8439b42aa8a5e24a47a}"
: "${CF_OPERATOR_VERSION:=5.0.0%2B0.gd7ac12bc}"

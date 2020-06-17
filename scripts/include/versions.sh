# shellcheck shell=bash

: "${MINIKUBE_ISO_URL:=https://github.com/f0rmiga/opensuse-minikube-image/releases/download/v0.1.6/minikube-openSUSE.x86_64-0.1.6.iso}"

: "${CF_OPERATOR_URL:=https://s3.amazonaws.com/cf-operators/release/helm-charts/cf-operator-{version\}.tgz}"
: "${CF_OPERATOR_SHA256:=64a2f93ec84909e5372fd89562d604b7680994535b1d392684dce74ec63bb74e}"
: "${CF_OPERATOR_VERSION:=4.5.6%2B0.gffc6f942}"

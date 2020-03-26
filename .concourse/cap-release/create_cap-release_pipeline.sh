#!/bin/bash
set -x

# NOTE for now, add your cluster's kubeconfig in git@github.com:SUSE/cf-ci-pools.git on branch ${BACKEND}-kube-hosts in unclaimed folder
# Usage example: PIPELINE=name-demo-release BACKEND='backend: [ caasp4, eks ]' OPTIONS='options: [ sa ]' EIRINI='eirini: [ diego ]' ./create_cap-release_pipeline.sh

export PIPELINE="${PIPELINE-cap-release}"

rm "$PIPELINE".yaml 2>/dev/null || true
export BACKEND="${BACKEND:-backend: [ caasp4, aks, gke, eks ]}"
export OPTIONS="${OPTIONS:-options: [ sa, ha, all ]}"
export EIRINI="${EIRINI:-eirini: [ diego, eirini ]}"

gomplate -d 'BACKEND=env:///BACKEND?type=application/yaml' \
         -d 'OPTIONS=env:///OPTIONS?type=application/yaml' \
         -d 'EIRINI=env:///EIRINI?type=application/yaml' \
         -f pipeline.template > "$PIPELINE".yaml

fly -t concourse.suse.dev sp -c "$PIPELINE".yaml -p "$PIPELINE"

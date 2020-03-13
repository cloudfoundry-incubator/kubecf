#!/bin/bash

# NOTE for now, to insert clusters by kubeconfig into EKCP (change name of cluster):
# curl -d "name=cap-release-diego-caasp4&kubeconfig=$(base64 ./kubeconfig)" -X POST http://ain.arch.suse.de:8030/api/v1/cluster/insert

export PIPELINE="${PIPELINE-cap-release}"

rm "$PIPELINE".yaml 2>/dev/null || true
export BACKEND="${BACKEND:-backend: [ caasp4, aks, gke, eks ]}"
export OPTIONS="${OPTIONS:-options: [ sa, ha, all ]}"
export EIRINI="${EIRINI:-eirini: [ diego, eirini ]}"

gomplate -d 'BACKEND=env:///BACKEND?type=application/yaml' \
         -d 'OPTIONS=env:///OPTIONS?type=application/yaml' \
         -d 'EIRINI=env:///EIRINI?type=application/yaml' \
         -f pipeline.template > "$PIPELINE".yaml

fly -t concourse.suse.dev dp "$PIPELINE".yaml -p "$PIPELINE"
fly -t concourse.suse.dev sp -c "$PIPELINE".yaml -p "$PIPELINE"

#!/bin/bash

# NOTE to insert clusters by kubeconfig into EKCP (change name of cluster):
# curl -d "name=post-publish-diego-caasp4&kubeconfig=$(base64 ./kubeconfig)" -X POST http://ain.arch.suse.de:8030/api/v1/cluster/insert

export PIPELINE=product-release

# Lets concatenate all the pipelines:
rm $PIPELINE.yaml
export BACKEND="${BACKEND:-backend: [ caasp4, aks, gke, eks ]}"

gomplate -d 'BACKEND=env:///BACKEND?type=application/yaml' -f backend.template > $PIPELINE.yaml

fly -t concourse.suse.dev dp $PIPELINE.yaml -p $PIPELINE
fly -t concourse.suse.dev sp -c $PIPELINE.yaml -p $PIPELINE

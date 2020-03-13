# Product release pipeline

[This pipeline](https://concourse.suse.dev/teams/main/pipelines/product-release)
tests KubeCF on Kubernetes distributions CaaSP4, GKE, EKS, AKS:
* Eirini or Diego enabled.
* Instance groups as single availability or high availability.
* Autoscaler enabled and disabled,
* Runs Smokes, CATS, Brain and SITS.
* Upgrades KubeCF deployment.
* Installs Stratos and metrics.

# Deploying pipeline

    $ ./create_product-release_pipeline.sh

If you want your own pipeline: `PIPELINE=yourname ./create_product-release_pipeline.sh`
See `BACKEND`, `OPTIONS`, `EIRINI` to disable some features on deployment if wanted.
The new `yourname` pipeline will make use of kuceconfigs uploaded to EKCP
(http://ain.arch.suse.de:8030/ui) named  `yourname-*`, eg `yourname-diego-caasp4-ha`.
So make sure to upload your own kubeconfig from your own cluster, see below.

# Implementation

The pipeline strives to have the minimum concourse yaml to do the job, and put
the logic somewhere so one can run and iterate on the pipeline locally.
It's still in flux.

# Current status

For now, the pipeline consumes clusters hardcoded by name: eg
`product-release-diego-caasp4-ha`.

The kubeconfigs for these clusters are stored in EKCP hosts, and are created
either manually or in an automated way by performing `BACKEND=foo make k8s` with
Catapult.

This hardcoding of kubeconfigs is needed until we have a fully-fledged Concourse
Pool system that can pass the correct kubeconfig from 1 horizontal job to the
next one (eg: deploy-diego-caasp4-ha -> smoke-tests-diego-casp4-ha). Until that
moment, we perform `BACKEND=ekcp make recover` as first step to obtain the kubeconfig.

Templating engine is not set in stone, either.

## Manually adding a cluster to catapult-web/EKCP
https://github.com/SUSE/catapult/wiki/Catapult-web#add-a-cluster-to-catapult-web

# CAP release pipeline

[This pipeline](https://concourse.suse.dev/teams/main/pipelines/product-release)
tests KubeCF on Kubernetes distributions CaaSP4, GKE, EKS, AKS:
* Eirini or Diego enabled.
* Instance groups as single availability or high availability.
* Autoscaler enabled and disabled,
* Runs Smokes, CATS, Brain and SITS.
* Upgrades KubeCF deployment.
* Installs Stratos and metrics.

# Deploying the pipeline

    $ ./create_cap-release_pipeline.sh

If you want your own pipeline: `PIPELINE=yourname ./create_cap-release_pipeline.sh`
See `BACKEND`, `OPTIONS`, `EIRINI` to disable some features on deployment.
The new `yourname` pipeline will make use of kuceconfigs uploaded to EKCP
(http://ain.arch.suse.de:8030/ui) named  `yourname-*`, e.g. `yourname-diego-caasp4-ha`.
So make sure to upload your own kubeconfig from your own cluster, see below.

# Implementation

The pipeline strives to have the minimum concourse yaml to do the job, and put
the logic somewhere so one can run and iterate on the pipeline locally.
It's still in flux.

# K8s cluster management

The pipeline consumes clusters by putting a lock on unclaimed kubeconfigs from git@github.com:SUSE/cf-ci-pools.git

Add your kubeconfigs to cf-ci-pools in ${Backend}-kube-hosts branch in unacliamed folder for CI to pick it up.

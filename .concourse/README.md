# Kubecf pipeline

[This pipeline](https://concourse.suse.dev/teams/main/pipelines/kubecf) lints
builds and tests kubecf both with Eirini and Diego. The clusters used are
GKE preemptible ones.

The pipeline tests the kubecf master branch as well as PRs with the tag
"Trigger: CI".

It uses [Catapult](https://github.com/SUSE/catapult) for the logic implementation.

## Deploying the pipeline

    $ ./create_pipeline.sh <concourse-target> <pipeline-name>

E.g: to deploy the `kubecf` pipeline:

    $ ./create_pipeline.sh <concourse-target> kubecf

E.g: to deploy the `kubecf-pool-reconciler` pipeline:

    $ ./create_pipeline.sh <concourse-target> kubecf-pool-reconciler

All the required config options are in `<pipeline-name>.yaml`.

### Pipeline development

If you wish to deploy a custom pipeline, you can copy and modify either
`kubecf.yaml` or `kubecf-pool-reconciler.yaml`. The name of your config file will
be used as the <pipeline-name>.


## Running the tests locally

It is possible to run the job of the pipeline locally without having a full
Concourse + GKE clusters.
Catapult allows to replicate every step regardless the Kubernetes provider.
[See the Catapult wiki page for a short summary on how to run the same tests
locally](https://github.com/SUSE/catapult/wiki/KubeCF-testing).

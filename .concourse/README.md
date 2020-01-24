# Post-publish pipeline

[This pipeline](https://concourse.suse.dev/teams/main/pipelines/post-publish) runs smoke and CATS tests of kubecf with Eirini and Diego on Kind.

It uses [Catapult](https://github.com/SUSE/catapult) and requires at least one EKCP host (or a federated EKCP network) to delegate the Kubernetes
cluster creation to another machine, so the concourse worker can just consume it.


## Deploy the pipeline

The following section describes the requirements and the steps needed to deploy the pipeline from scratch.

### Requirements

The only requirement of this pipeline is a [EKCP](https://github.com/mudler/ekcp) instance deployed in the network, which the concourse workers can reach.

EKCP is an API on top of Kind that allows to create clusters programmatically and let access Kind clusters them from outside.

For more informations, see also [EKCP Deployment setup](https://github.com/mudler/ekcp/wiki/Deployment-setups) on how to set-up a EKCP node in a local network, also [see the Catapult-web wiki page](https://github.com/SUSE/catapult/wiki/Catapult-web) for a full guided setup.

### Switching EKCP node

To make the pipeline request new clusters from a different node, only adjust the `EKCP_HOST` parameter on the pipelines/environment variable accordingly to point to your new EKCP API endpoint.

## Deploy on Concourse

If you wish to deploy the pipeline on Concourse, just run as usual:

```
fly -t target set-pipeline -c post-publish.yaml -p post-publish
```


# Workflow for BOSH Release Authors

BOSH release authors, who want to test their development code with the Quarks operator, need to build a Docker image from their release.
This can be done with fissile.
Afterwards the image can be uploaded to the test cluster and  tested locally with

## Building a Docker Image with Fissile

Build the BOSH release first and transform it with fissile.

https://github.com/cloudfoundry-incubator/cf-operator-ci/blob/master/pipelines/release-images/tasks/build.sh#L30

## Uploading The Image

Depending on your cluster, you'll need to get the locally build image to Kubernetes registry.

With minikube you can build directly on minikube's Docker, run `eval $(minikube docker-env)`, before you build the image with fissile.

With kind, you need to use `kind load docker-image` to make it available, i.e.:

```
kind load docker-image docker.io/cfcontainerization/cf-operator:0.1-dev
```

## Testing With SCFv3

Afterwards build and deploy SCF according to the [SCFv3 docs](https://github.com/SUSE/scf/blob/v3-develop/dev/scf/docs/installing.md).

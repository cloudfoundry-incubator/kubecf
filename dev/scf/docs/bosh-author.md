# Workflow for BOSH Release Authors

This document describes how SCF and Quarks can be used for BOSH release development.

## Preparing the Release Image

BOSH release authors, who want to test their development code with the Quarks operator, need to build a Docker image from their release.
This can be done with fissile.
Afterwards the image can be uploaded to the test cluster and  tested locally with

### Building a Docker Image with Fissile

Build the BOSH release first and transform it with fissile.

https://github.com/cloudfoundry-incubator/cf-operator-ci/blob/master/pipelines/release-images/tasks/build.sh#L30

### Uploading The Image

Depending on your cluster, you'll need to get the locally build image to Kubernetes registry.

With minikube you can build directly on minikube's Docker, run `eval $(minikube docker-env)`, before you build the image with fissile.

With kind, you need to use `kind load docker-image` to make it available, i.e.:

```
kind load docker-image docker.io/cfcontainerization/cf-operator:0.1-dev
```

## Integrating the Release in SCF

With Quarks and SCF BOSH releases can largely be used just the same as with a BOSH director. There are a few things Quarks offers to make adaption to the kubernetes environment easier, though.

### BPM

BPM configurations for jobs are parsed from the `config/bpm.yml` as usual. But if need be, it is also possible to override the BPM configuration in the deployment manifest in the `quarks` field. See [the bpm documentation](https://bosh.io/docs/bpm/config/) for details on how to configure BPM.

Example:

```yaml
instance_groups:
- name: nats
  instances: 2
  jobs:
  - name: nats
    properties:
      quarks:
        bpm:
          processes:
          - name: nats
            limits:
              open_files: 50
            executable: /var/vcap/packages/gnatsd/bin/gnatsd
            args:
            - -c
            - "/var/vcap/jobs/nats/config/nats.conf"
```

Note: See [ops files](#ops-files) for how this can be applied without the need to modify the original deployment manifest using ops files.

### ops files

[ops files](https://bosh.io/docs/cli-ops-files/) can be used to modify arbitrary parts of the deployment manifest before it is being applied. To do so create an according file in `deploy/helm/scf/assets/operations/instance_groups` and it will automagically be applied during installation.

The ops file for the example above could look like this:

```yaml
- type: replace
  path: /instance_groups/name=nats/jobs/name=nats/properties/quarks?/bpm/processes
  value:
  - name: nats
    limits:
      open_files: 50
    executable: /var/vcap/packages/gnatsd/bin/gnatsd
    args:
    - -c
    - "/var/vcap/jobs/nats/config/nats.conf"

```


## Testing With SCFv3

Afterwards build and deploy SCF according to the [SCFv3 docs](https://github.com/SUSE/scf/blob/v3-develop/dev/scf/docs/installing.md).

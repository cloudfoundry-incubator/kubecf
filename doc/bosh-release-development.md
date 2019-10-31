# Developing BOSH releases with Kubecf and Quarks

## Table Of Contents

  -  [Preparing the Release Image](#preparing-the-release-image)
       - [Building a Docker Image with Fissile](#building-a-docker-image-with-fissile)
       - [Uploading The Image](#uploading-the-image)
       - [Modify Kubecf to Use the New Image](#modify-kubecf-to-use-the-new-image)
  -  [Integrating the Release in Kubecf](#integrating-the-release-in-kubecf)
       - [BPM](#bpm)
       - [Operation Files](#operation-files)
  -  [Testing With Kubecf](#testing-with-kubecf)

## Preparing the Release Image

BOSH release authors, who want to test their development code with the
Quarks operator, need to build a Docker image from their release.
This can be done with `fissile`.  Afterwards upload the image to a
cluster for testing it, e.g. with Kubecf.

### Building a Docker Image with Fissile

Build the BOSH release first and convert it with [fissile].

To generate a docker image from the BOSH release, you should use the
following subcommand:

```sh
fissile build release-image
```

For more information on how to use the command, please refer to the
related [documentation]. For a real example, see [build.sh].

[fissile]:       https://github.com/cloudfoundry-incubator/fissile
[documentation]: https://github.com/cloudfoundry-incubator/fissile/blob/develop/docs/build-docker-imgs.md
[build.sh]:      https://github.com/cloudfoundry-incubator/cf-operator-ci/blob/e83e46548787ee740ea1918182604faaa5cddf8f/pipelines/release-images/tasks/build.sh#L34

### Uploading The Image

Depending on your cluster, you will need a way to get the locally
built image into the Kubernetes registry.

With __minikube__ you can build directly on minikube's Docker. Switch
to that docker daemon by running `eval $(minikube docker-env)`, before
you build the image with `fissile`.

With __kind__, you need to use `kind load docker-image` after building
the image, to make it available, i.e.:

```sh
kind load docker-image docker.io/org/nats:0.1-dev
```

### Modify Kubecf to Use the New Image

Add an operations file to Kubernetes with the new image location. The
example below uses NATS as the example for a BOSH release.

```yaml
kubectl apply -f - <<EOF
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: nats-dev
data:
  ops: |
- type: replace
  path: /releases/name=nats?
  value:
    name: nats
    url: docker.io/org/nats
    version: 0.1-dev
    sha1: ~
EOF
```

Then, when running `helm install scf` refer to that image:

```sh
helm install ... --set 'operations.custom={nats-dev}'
```

__Note__: You can also unpack the helm release and modify it directly.
There is no need to zip the release again, as `helm install scf/` is
able to install the unpacked release.

Note further that the above is an example of how to use the first kind
of customization feature noted in the main [README](Contribute.md#customization).

## Integrating the Release in Kubecf

With Quarks and Kubecf BOSH releases can largely be used just the same
as with a BOSH director. There are a few things Quarks offers however
to make adaption to the kubernetes environment easier.

### BPM

BPM configurations for jobs are parsed from a rendered `bpm.yml`, as
usual. But if need be, it is also possible to override BPM
configuration in the deployment manifest in the `quarks` field. See
[the bpm documentation] for details on how to configure BPM.

[the bpm documentation]: https://bosh.io/docs/bpm/config/

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

Note: The next section on [ops files](#operation-files) explains how
this can be applied without the need to modify the original deployment
manifest using ops files.

### Operation Files

[ops files] can be used to modify arbitrary parts of the deployment
manifest before being applied. To do so, create a file in the
directory `deploy/helm/scf/assets/operations/instance_groups` and it
will be automagically applied during installation, courtesy of the
bazel machinery.

[ops files]: https://bosh.io/docs/cli-ops-files/

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

## Testing With Kubecf

After upload and integration it is possible to build and deploy Kubecf
according to any of the recipes listed by the main
[README](Contribute.md#deployment).

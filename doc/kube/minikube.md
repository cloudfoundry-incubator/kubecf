# Minikube

## Attention

Minikube edits the kubernetes configuration file referenced by the
environment variable `KUBECONFIG`, or `~/.kube/config`.

To preserve the original configuration either make a backup of the
relevant file, or change `KUBECONFIG` to a different path specific to
the intended deployment.

## Deployment and teardown

For developing with Minikube, start a local cluster by running the `start` target:

```sh
bazel run //dev/minikube:start
```

And tear it down again via:

```sh
bazel run //dev/minikube:delete
```

## Managing system resources

The following three environment variables are used by the `start`
target to allocate the resources used by the deployed Minikube:

  - VM_CPUS - the number of CPUs Minikube will use.
  - VM_MEMORY - the amount of RAM Minikube will be allowed to use.
  - VM_DISK_SIZE - the disk size Minikube will be allowed to use.

E.g.:

```sh
VM_CPUS=6 VM_MEMORY=$((1024 * 24)) VM_DISK_SIZE=180g bazel run //dev/minikube:start
```

## Specifying a different Kubernetes version

Set the `K8S_VERSION` environment variable to override the default version.

## VM Drivers

At the moment, only the VirtualBox and KVM2 drivers are working correctly. Set the `VM_DRIVER`
environment variable to override the default. E.g. `VM_DRIVER=kvm2`.

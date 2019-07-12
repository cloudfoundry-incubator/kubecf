# Minikube

For developing with Minikube, start a local cluster by running the `start` target:

```txt
bazel run //dev/minikube:start
```

## Managing system resources

The following environment variables are used by the `start` target to allocate the resources used by
Minikube:

  - VM_CPUS - the number of CPUs Minikube will use.
  - VM_MEMORY - the amount of RAM Minikube will be allowed to use.
  - VM_DISK_SIZE - the disk size Minikube will be allowed to use.

E.g.:

```txt
VM_CPUS=6 VM_MEMORY=$((1024 * 24)) VM_DISK_SIZE=180g bazel run //dev/minikube:start
```

## Specifying a different Kubernetes version

Set the `K8S_VERSION` environment variable to override the default version.

## Deploying SCF to Minikube

With Minikube started and the cf-operator running for the namespace `scf`, run the target:

```txt
bazel run //dev/minikube:apply_scf
```

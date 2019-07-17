# SCF

The targets under `scf` are used to apply the rendered Helm template to a Kubernetes cluster.
Any `*values.yaml` files under this directory is ignored by git, but used by Bazel to render the SCF
chart before applying to the cluster with kubectl.

## Apply

Run:

```txt
bazel run //dev/scf:apply
```

## Delete

Run:

```txt
bazel run //dev/scf:delete
```

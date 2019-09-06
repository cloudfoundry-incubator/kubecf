# SCF

The targets under `scf` are used to apply the rendered Helm template to a Kubernetes cluster.
Any `*values.yaml` files under this directory are ignored by git, but used by Bazel to render the
SCF chart before applying to the cluster with kubectl.

The [docs](./docs/) sub-directory contains more details. Start with
[Installing SCF](./docs/installing.md).

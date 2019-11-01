# Kubecf

The target defined by directory __dev/kubecf__ are used to apply the
rendered Helm template to a Kubernetes cluster.

__Attention__: While any files matching the glob pattern
`*values.yaml` and found in this directory are ignored by git, they
are used by Bazel to render the SCF chart before applying to the
cluster with kubectl.

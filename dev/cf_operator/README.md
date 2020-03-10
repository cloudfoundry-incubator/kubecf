# cf-operator

The target defined in directory `dev/cf_operator` is used to install
[cf-operator] to a Kubernetes cluster.

__Attention__: While any files matching the glob pattern `*values.yaml` and
found in this directory are ignored by git, they are used by Bazel to install
the [cf-operator chart].

[cf-operator]: https://github.com/cloudfoundry-incubator/cf-operator
[cf-operator chart]: https://hub.helm.sh/charts/quarks/cf-operator

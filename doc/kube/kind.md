# Kind

## Attention

After starting a cluster, it is necessary to retrieve the path of the
kubernetes configuration file from KinD.

The necessary command is:

```shell
export KUBECONFIG="$(bazel run @kind//kind -- get kubeconfig-path --name="kubecf")"
```

## Deployment and teardown

For developing with [KinD], start a local cluster by running the `start` target:

[KinD]: https://github.com/kubernetes-sigs/kind

```shell
bazel run //dev/kind:start
```

And tear it down via:

```shell
bazel run //dev/kind:delete
```

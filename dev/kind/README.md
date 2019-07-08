# Kind

For developing with [kind](https://github.com/kubernetes-sigs/kind), start a local cluster by running the `start` target:

```shell
bazel run //dev/kind:start
```

Don't forget to also set your `KUBECONFIG`:

```shell
export KUBECONFIG="$(kind get kubeconfig-path --name="scf")"
```

## Cleanup

```shell
bazel run //dev/kind:clean
```

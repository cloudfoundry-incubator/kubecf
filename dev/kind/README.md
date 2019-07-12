# Kind

For developing with [kind](https://github.com/kubernetes-sigs/kind), start a local cluster by
running the `start` target:

```shell
bazel run //dev/kind:start
```

Don't forget to also set your `KUBECONFIG`:

```shell
export KUBECONFIG="$(bazel run @kind//:kind -- get kubeconfig-path --name="scf")"
```

## Cleanup

```shell
bazel run //dev/kind:delete
```

## Deploying SCF to Kind

With Kind started and the cf-operator running for the namespace `scf`, run the target:

```txt
bazel run //dev/kind:apply_scf
```

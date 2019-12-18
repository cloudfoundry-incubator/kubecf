# Kind

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

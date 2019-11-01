# Testing

The smoke and acceptance tests can be run after Kubecf deployment has
completed, via:

```sh
bazel run //testing/smoke_tests
bazel run //testing/acceptance_tests
```

The [acceptance tests] can be limited to specific suites of interest,
as explained in the linked document.

[acceptance tests]: tests_cat.md

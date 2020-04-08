# Testing

The smoke, brain, acceptance, and sync integration tests can be run after KubeCF
deployment has completed, via:

```sh
bazel run //testing:smoke_tests
bazel run //testing:brain_tests
bazel run //testing:acceptance_tests
bazel run //testing:sync_integration_tests
```

The [acceptance tests] can be limited to specific suites of interest,
as explained in the linked document.

[acceptance tests]: tests_cat.md

# Guide To Contribution

The intended audience of this document are developers wishing to
contribute to the Kubecf project.

It provides a basic overview of various aspects of the project, from
which it when launches to other documentation going deeper into
specific details of that aspect.

## Table of Contents (Aspects)

  - [Deployment](#deployment)
  - [Pull Requests](#pull-requests)
  - [Source Organization](#source-organization)
  - [Linting](#linting)

## Deployment

Kubecf is build on top of a number of technologies, namely Kubernetes,
Helm (charts), and the CF operator (for the translation of BOSH
deployments into Kubernetes objects).

For all these we have multiple choices for installing them, and
various interactions between the choices influence the details of the
commands to use.

Instead of trying to document all the possibilities and all their
interactions at once supporting documents will describe specific
combinations of choices in detail, from the bottom up.

|Document		|Description						|
|---			|---	   						|
|[MOK_BRC](mok_brc.md)	|Minikube/Bazel + Operator/Release + Kubecf/Checkout	|

## Pull Requests

The general work flow for pull requests contributing bug fixes,
features, etc. is

  - Branch or Fork the __suse/kubecf__ repository, depending on
    permissions.

  - Implement the bug fix, feature, etc. on that branch/fork.

  - Submit a pull request based on the branch/fork through the github
    web interface, against the __master__ branch.

  - Developers will review the content of the pull request, asking
    questions, requesting changes, and generally discussing the
    submission with the submitter and among themselves.

  - After all issues with the request are resolved, and CI has passed
    a developer will merge it into master.

  - Note that it may be necessary to rebase the branch/fork to resolve
    any conflicts due to other PRs getting merging while the PR is
    under discussion.

    Such a rebase will be a change request from the developers to the
    contributor, on the assumption that the contributor is best suited
    to resolving the conflicts.

## Source Organization

The important directories of the kubecf sources, and their contents
are:

|Directory			|Content						|
|---				|---							|
|__top__			|Documentation entrypoint, License,			|
|				|Main workspace definitions				|
|__top__/.../README.md		|Directory-specific local documentation			|
|__top__/bosh/releases		|Support for runtime patches of a kubecf deployment	|
|__top__/doc			|Global documentation					|
|__top__/dev/cf_deployment/bump |Tools to support updating the cf deployment		|
|				|manifest used by kubecf				|
|__top__/dev/cf_cli		|Deploy cf cli into a helper pod from which to then	|
|				|inspect the deployed CF				|
|__top__/dev/kube		|Tools to inspect kube clusters and kubecf deployments	|
|__top__/dev/linters		|Tools for statically checking the kubecf sources	|
|__top__/dev/minikube		|Targets to manage a local kubernetes cluster		|
|				|minikube based						|
|__top__/dev/scf		|Kubecf chart configuration, and targets for		|
|				|local chart application				|
|__top__/deploy/helm/scf	|Templates and assets wrapping a CF deployment		|
|				|manifest into a helm chart				|
|__top__/rules			|Supporting bazel definitions				|
|__top__/testing		|Bazel targets to run CF smoke and acceptance tests	|

## Linting

Currently only one linter is available:

  - `dev/linters/shellcheck.sh`

Invoke this linter as

```sh
dev/linters/shellcheck.sh
```

to run shellcheck on all `.sh` files found in the entire checkout and
report any issues found.

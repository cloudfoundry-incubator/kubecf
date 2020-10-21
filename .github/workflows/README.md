# GitHub Workflows

This directory contains the definitions for [GitHub Actions workflows].

[GitHub Actions workflows]: https://docs.github.com/en/free-pro-team@latest/actions/reference/workflow-syntax-for-github-actions

<!-- omit in toc -->
## Table of Contents
- [Building & Testing](#building--testing)
- [Pull Request Summary Linting](#pull-request-summary-linting)

## Building & Testing

The pull request & continuous integration workflow is:

- On pull requests approval, [`pull-request-queue.yaml`] adds a [`pr-test-queue`]
  label to pull requests that are eligible for building.
- Humans may also manually attach the [`pr-test-queue`] label to pull requests
  to trigger builds without approval or to re-trigger builds.
- Every 10 minutes, [`pull-request-schedule.yaml`] will check for capacity to
  run tests:
  - Check for clusters that are labelled as being triggered by GitHub PRs, but
    which do not have matching PR runs, and initiate deletion.
  - If we do not have capacity for additional clusters, abort and wait to be
    triggered again next time.
  - For each cluster we have capacity for:
    - Locate the issue with the oldest [`pr-test-queue`] label, and:
      - Remove the label
      - Apply a [`pr-test-trigger`] label
- Upon the [`pr-test-trigger`] label being applied, [`pull-request-ci.yaml`]
  will remove the label again and run tests.

[`pull-request-queue.yaml`]: pull-request-queue.yaml
[`pr-test-queue`]: https://github.com/cloudfoundry-incubator/kubecf/issues?q=label%3Apr-test-queue
[`pull-request-schedule.yaml`]: pull-request-schedule.yaml
[`pr-test-trigger`]: https://github.com/cloudfoundry-incubator/kubecf/issues?q=label%3Apr-test-trigger
[`pull-request-ci.yaml`]: pull-request-ci.yaml

## Pull Request Summary Linting

[`conventional-commits-lint.yml`] checks that pull requests have a summary that
follows [Conventional Commits], as specified in [RFD 002].

[`conventional-commits-lint.yml`]: conventional-commits-lint.yml
[Conventional Commits]: https://www.conventionalcommits.org/en/v1.0.0/
[RFD 002]: /doc/rfd/rfd/0002/README.md

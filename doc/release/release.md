# Release Flow

## Introduction

The KubeCF release life cycle approach is similiar to the [trunk based development](https://trunkbaseddevelopment.com/), where *master* is used to merge features and from where a *release* branch is created to cut a new version.

KubeCF follows the [semver](https://semver.org/) for versioning and does it automatically by inspecting the git *release* branch name.

## Releasing

A *release* branch is created from the *master* and can ONLY get bug-fix commits. When fixes are added, then a manual cherry-pick to the *master* will happen immediately after.

### Minor and Patch Releases

Each minor release uses it's own release branch named `release-x.y`. Further patch releases will always be made from this release branch, by cherry-picking bug fixes from either `master` or specific bug-fix branches.

![](https://i.imgur.com/b2DVvMw.png)

> Read more about release proposal [here]( https://docs.google.com/document/d/1xPkFhS_0zSfyzMIHUb1q3lmILwVm0ft1ksLSMv3KWZI/edit?usp=sharing)

## Github Release

After having the release template ready and the CI pipeline checked, it's time to create a new release on Github and for that, just go to the Github project release [page](https://github.com/SUSE/kubecf/releases) and follow the
Github release flow.
v0.0.0-alpha draft can be used as guideline and don't forget to open PR against this document if you have better ideas and/or if you find any incorrections.

As part of the end of a release cycle, all the Github issues under the _done_ column will be archived.

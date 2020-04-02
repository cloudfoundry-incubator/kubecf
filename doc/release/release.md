# Release Flow

## Introduction

The KubeCF release life cycle approach is similiar to the [trunk based development](https://trunkbaseddevelopment.com/), where *master* is used to merge features and from where a *release* branch is created to cut a new version.

KubeCF follows the [semver](https://semver.org/) for versioning and does it automatically by inspecting the git *release* branch name.

## Releasing

A *release* branch is created from the *master* and can ONLY get bug-fix commits. When fixes are added, then a manual cherry-pick to the *master* will happen immediately after.

If the *release* branch name is not semver compatible, a version 0.0.0 will be associated to the KubeCF package indicating an **UNOFFICIAL** package release.

Examples

* git *release* branch named **v1.0.0** will generate a **KubeCF-v1.0.0** package file :+1:
* git branch name **non-semver** will generate a **KubeCF-v0.0.0** package file that indicates it's an **UNOFFICIAL** release.

### Minor and Patch Releases

A minor or a patch release can occur during a version life cyle and if so, a *release patch* branch MUST be created from the original *release* branch version and it will contain the improvements and/or bug fixes that later will be cherry-picked into the *master* branch.

![](https://i.imgur.com/b2DVvMw.png)

> Read more about release proposal [here]( https://docs.google.com/document/d/1xPkFhS_0zSfyzMIHUb1q3lmILwVm0ft1ksLSMv3KWZI/edit?usp=sharing)

## Github Release

After having the release template ready and the CI pipeline checked, it's time to create a new release on Github and for that, just go to the Github project release [page](https://github.com/SUSE/kubecf/releases) and follow the
Github release flow.
v0.0.0-alpha draft can be used as guideline and don't forget to open PR against this document if you have better ideas and/or if you find any incorrections.

As part of the end of a release cycle, all the Github issues under the _done_ column will be archieved.

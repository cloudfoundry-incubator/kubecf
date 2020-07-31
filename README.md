# KubeCF

| Build step | State |
| ---     | ---   |
| Linting | [![lint](https://concourse.suse.dev/api/v1/teams/main/pipelines/kubecf/jobs/lint-master/badge)](https://concourse.suse.dev/teams/main/pipelines/kubecf/jobs/lint-master/) |
| Building | [![build](https://concourse.suse.dev/api/v1/teams/main/pipelines/kubecf/jobs/build-master/badge)](https://concourse.suse.dev/teams/main/pipelines/kubecf/jobs/build-master/) |
| Smoke tests on Diego | [![smoke-diego](https://concourse.suse.dev/api/v1/teams/main/pipelines/kubecf/jobs/smoke-tests-diego-master/badge)](https://concourse.suse.dev/teams/main/pipelines/kubecf/jobs/smoke-tests-diego-master/) |
| Smoke tests on Eirini | [![smoke-eirini](https://concourse.suse.dev/api/v1/teams/main/pipelines/kubecf/jobs/smoke-tests-eirini-master/badge)](https://concourse.suse.dev/teams/main/pipelines/kubecf/jobs/smoke-tests-eirini-master/) |
| Acceptance Tests on Diego | [![acceptance-diego](https://concourse.suse.dev/api/v1/teams/main/pipelines/kubecf/jobs/cf-acceptance-tests-diego-master/badge)](https://concourse.suse.dev/teams/main/pipelines/kubecf/jobs/cf-acceptance-tests-diego-master/) |
| Acceptance Tests on Eirini | [![acceptance-diego](https://concourse.suse.dev/api/v1/teams/main/pipelines/kubecf/jobs/cf-acceptance-tests-eirini-master/badge)](https://concourse.suse.dev/teams/main/pipelines/kubecf/jobs/cf-acceptance-tests-eirini-master/) |

## Introduction

KubeCF is a distribution of Cloud Foundry Application Runtime (CFAR) for Kubernetes. 
It works with the [cf-operator] from [Project Quarks] to deploy and manage releases built from [cf-deployment].

[cf-operator]:   https://github.com/cloudfoundry-incubator/cf-operator/
[Project Quarks]:           https://www.cloudfoundry.org/project-quarks/
[cf-deployment]: https://github.com/cloudfoundry/cf-deployment/
[Docs]:                     https://kubecf.suse.dev/

## Documentation

The Community documentation website is [available here](https://kubecf.suse.dev/).

## Contributing to KubeCF development

See the [Guide to Contribution](doc/Contribute.md).

# System requirements

To work with `kubecf`, a variety of supporting tools are required.
These are:

| Tool          | Notes                                                  |
|---            |---                                                     |
|k8s            | The platform to run KubeCF.                            |
|minikube       | Provider for local k8s clusters.                       |
|kind           | Provider for local k8s clusters.                       |
|kubectl        | Client to talk to k8s clusters.                        |
|Helm           | Handling helm charts.                                  |
|[cf-operator]  | Processes BOSH deployments. Maps them to kube objects. |
|[cf-deployment]| The CF release at the core of `kubecf`.                |

As most of the developers use the `Bazel` build system coming with the
`kubecf` repository, they implicitly use the versions for the tools
set down in `Bazel`'s main project configuration file, `def.bzl`.

At the time of this writing these were:

| Tool         | Version           | Notes                              |
|---           |---                |---                                 |
|Kubernetes    | 1.15.6            |                                    |
|minikube      | 1.6.2             |                                    |
|kind          | 0.6.0             |                                    |
|kubectl       | 1.15.6            |                                    |
|Helm          | 3.0.3             |                                    |
|CF Operator   | 5.0.0+0.gd7ac12bc |                                    |
|cf-deployment | 13.9.0           |                                    |

__Note however__: As `kubecf` is updated these versions may change
from commit to commit.  The table above is therefore
__not authoritative__.

__Always__ check the contents of `def.bzl` for the authoritative
answer.

__Note further__: Just because the build system provides targets to
conveniently bring up a local k8s cluster using minikube or kind, this
does not preclude the use of other k8s cluster providers, local or in
the cloud.

Besides the required tools noted above, other tools used by developers
are:

| Tool  | Notes                         | Location                         |
|---    |---                            |---                               |
|k9s    | Curses-based UI over kubectl  | https://github.com/derailed/k9s  |
|stern  | Multi-pod log tailing         | https://github.com/wercker/stern |

Last, but not least, __more documentation__ on how to work with
`kubecf` is found in the [Guide to Contribution](doc/Contribute.md).

## Useful Information

| What                                   | Where                                                        |
| -------------------------------------- | ------------------------------------------------------------ |
| Concourse Pipeline                     | https://concourse.suse.dev/teams/main/pipelines/kubecf       |
| S3 Bucket with helm charts<sup>*</sup> | https://kubecf.s3.amazonaws.com/index.html                   |
| Cloud Foundry Operator                 | https://github.com/cloudfoundry-incubator/cf-operator/       |
| CF Operator Charts                     | https://cf-operators.s3.amazonaws.com/helm-charts/index.html |

<sub>* The bundle file includes the operator chart</sub>

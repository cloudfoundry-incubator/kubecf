[![pipeline status](https://gitlab.com/susecf/kubecf/badges/master/pipeline.svg)](https://gitlab.com/susecf/kubecf/pipelines)

# Kubecf

Cloud Foundry built for Kubernetes (formerly [SUSE/scf v3 branch]).
It makes use of the [Cloud Foundry Operator], which is incubating
under [Project Quarks].

[SUSE/scf v3 branch]:     https://github.com/SUSE/scf/tree/v3
[Cloud Foundry Operator]: https://github.com/cloudfoundry-incubator/cf-operator/
[Project Quarks]:         https://www.cloudfoundry.org/project-quarks/

## Contributing to Kubecf development

See the [Guide to Contribution](doc/Contribute.md).

# System requirements

To work with `kubecf` a variety of supporting tools are required. These are

| Tool		| Notes					|
|---		|---					|
|k8s		| Foundation.				|
|minikube	| Provider for local k8s clusters.	|
|kind		| Provider for local k8s clusters.	|
|kubectl	| Client to talk to k8s clusters.	|
|Helm (client)	| Handling helm charts.			|
|Helm (server)	| __Tiller is not required__.		|
|CF Operator	| Processes BOSH deployments. Maps them to kube objects.	|
|cf-deployment	| The CF release at the core of kubecf				|

As most of the developers use the `Bazel` build system coming with the
`kubecf` repository they implicitly use the versions for the tools set
down in `Bazel`'s main configuration file, `def.bzl`.

At the time of this writing these were:

| Tool		| Version		|
|---		|---			|
|k8s		| 1.15.6		|
|minikube	| 1.6.2			|
|kind		| 0.6.0			|
|kubectl	| 1.15.6		|
|Helm (client)	| 2.16.1		|
|Helm (server)	| n/a			|
|CF Operator	| 2.0.0-0.g0142d1e9	|
|cf-deployment	| 12.18.0

__Note however__: As `kubecf` is updated these versions may change
from commit to commit.  The table above is therefore
__not authoritative__.

__Always__ check the contents of `def.bzl` for the authoritative
answer.

__Note further__: Just because the build system provides targets to
conveniently bring up a local k8s cluster using minikube or kind, this
does not preclude the use of other k8s cluster providers, local or in
the cloud.

Beside the required tools noted above other tools used by developers are

| Tool  | Notes				| Location				|
|---	|---				|---					|
|k9s	| Curses-based UI over kubectl	| https://github.com/derailed/k9s	|
|stern	| Multi-pod log tailing		| https://github.com/wercker/stern	|

Last, but not least __more documentation__ on how to work with
`kubecf` is found in the [Guide to Contribution](doc/Contribute.md).

## Useful Information

| What                       | Where                                                        |
| -------------------------- | ------------------------------------------------------------ |
| GitLab Pipeline            | https://gitlab.com/susecf/kubecf/pipelines                   |
| S3 Bucket with helm charts | https://scf-v3.s3.amazonaws.com/index.html                   |
| Cloud Foundry Operator     | https://github.com/cloudfoundry-incubator/cf-operator/       |
| CF Operator Charts         | https://cf-operators.s3.amazonaws.com/helm-charts/index.html |

## Contributing to Kubecf development

See the [Guide to Contribution](doc/Contribute.md).

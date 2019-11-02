# Guide To Contribution

The intended audience of this document are developers wishing to
contribute to the Kubecf project.

It provides a basic overview of various aspects of the project below,
and uses these overviews as the launching points to other documents
which go deeper into the details of each aspect.

## Table of Contents (Aspects)

  - [Deployment](#deployment)
  - [Pull Requests](#pull-requests)
  - [Source Organization](#source-organization)
  - [Linting](#linting)
  - [Patching](#patching)
  - [BOSH Development Workflow]

## Deployment

Kubecf is built on top of a number of technologies, namely Kubernetes,
Helm (charts), and the [cf-operator] (for the translation of BOSH
deployments into Kubernetes objects).

[cf-operator]: https://github.com/cloudfoundry-incubator/cf-operator

For all these we have multiple choices for installing them, and
various interactions between the choices influence the details of the
commands to use.

Instead of trying to document all the possibilities and all their
interactions at once, supporting documents will describe specific
combinations of choices in detail, from the bottom up.

|Document                          |Description                                    |
|---                               |---                                            |
|[Local Minikube](dev/minikube.md) |Minikube/Bazel + Operator/Bazel + Kubecf/Bazel |
|[General Kube](dev/general.md)    |Any Kube + Operator/Helm + Kubecf/Helm         |

## Pull Requests

The general work flow for pull requests contributing bug fixes,
features, etc. is:

  - Branch or Fork the __suse/kubecf__ repository, depending on
    permissions.

  - Implement the bug fix, feature, etc. on that branch/fork.

  - Submit a pull request based on the branch/fork through the github
    web interface, against the __master__ branch.

  - Developers will review the content of the pull request, asking
    questions, requesting changes, and generally discussing the
    submission with the submitter and among themselves.

  - After all issues with the request are resolved, and CI has passed,
    a developer will merge it into master.

  - Note that it may be necessary to rebase the branch/fork to resolve
    any conflicts due to other PRs getting merging while the PR is
    under discussion.

    Such a rebase will be a change request from the developers to the
    contributor, on the assumption that the contributor is best suited
    to resolving the conflicts.

## Source Organization

The important directories of the kubecf sources, and their contents
are shown in the table below. Each directory entry links to the
associated documentation, if we have any.

|Directory                                                              |Content                                                |
|---                                                                    |---                                                    |
|__top__                                                                |Documentation entrypoint, License,                     |
|                                                                       |Main workspace definitions.                            |
|__top__/.../README.md                                                  |Directory-specific local documentation.                |
|[__top__/bosh/releases](../bosh/releases/pre_render_scripts/README.md) |Support for runtime patches of a kubecf deployment.    |
|__top__/doc                                                            |Global documentation.                                  |
|[__top__/dev/cf_deployment/bump](cf_deployment/bump.md)                |Tools to support updating the cf deployment            |
|                                                                       |manifest used by kubecf.                               |
|[__top__/dev/cf_cli](cf_cli.md)                                        |Deploy cf cli into a helper pod from which to then     |
|                                                                       |inspect the deployed Kubecf                            |
|[__top__/dev/kube](inspection.md)                                      |Tools to inspect kube clusters and kubecf deployments. |
|[__top__/dev/linters](linters.md)                                      |Tools for statically checking the kubecf sources.      |
|[__top__/dev/minikube](kube/minikube.md)                               |Targets to manage a local kubernetes cluster.          |
|                                                                       |Minikube based.                                        |
|[__top__/dev/kind](kube/kind.md)                                       |Targets to manage a local kubernetes cluster.          |
|                                                                       |KinD based (Kube-in-Docker).                           |
|[__top__/dev/kubecf](../dev/kubecf/README.md)                          |Kubecf chart configuration, and targets for            |
|                                                                       |local chart application.                               |
|__top__/deploy/helm/kubecf                                             |Templates and assets wrapping a CF deployment          |
|                                                                       |manifest into a helm chart.                            |
|__top__/rules                                                          |Supporting bazel definitions.                          |
|[__top__/testing](tests.md)                                            |Bazel targets to run CF smoke and acceptance tests.    |

## Linting

Currently only one linter is available:

  - `dev/linters/shellcheck.sh`

Invoke this linter as

```sh
dev/linters/shellcheck.sh
```

to run shellcheck on all `.sh` files found in the entire checkout and
report any issues found.

## Patching

### Background

The main goal of the CF operator is to take a BOSH deployment
manifest, deploy it, and have it run as-is.

Naturally, in practice, this goal is not quite reached yet, requiring
patching of the deployment manifest in question, and/or the
involved releases, at various points of the deployment process. The
reason behind a patch is generally fixing a problem, whether it be
from the translation into the kube environment, an issue with an
underlying component, or something else.

Then, there are features, given the user of the helm chart wrapped
around the deployment manifest the ability to easily toggle various
preset configurations, for example the use of eirini instead of diego
as the application scheduler.

### Features

A feature of kubecf is usually implemented using a combination of
[Helm templating] and [BOSH ops files].

[Helm templating]: https://helm.sh/docs/chart_template_guide/
[BOSH ops files]:  https://bosh.io/docs/cli-ops-files/

The helm templating is used to translate the properties in the chart's
values.yaml to the actual actions to take, by including/excluding
chart elements, often the BOSH ops files containing the structured
patches modifying the deployment itself (changing properties,
adding/removing releases, (de)activating jobs, etc.)

The helm templating is applied when the kubecf chart is deployed.

The ops files are then applied by the operator, transforming the base
manifest from the chart into the final manifest to deploy.

### Customization

Kubecf provides two mechanisms for customization during development
(and maybe by operators ?):

  1. The property `.Values.operations.custom` of the chart is a list
     of names for kube configmaps containing the texts of the ops
     files to apply beyond the ops files from the chart itself.

     Note that we are talking here about a yaml structure whose
     `data.ops` property is a __text block__ holding the yaml
     structure of an ops file.

     There is no tooling to help the writer with the ensuing quoting
     hell.

     Note further that the resulting config maps have to be applied,
     i.e. uploaded into the kube cluster __before__ deploying the
     kubecf helm chart with its modified values.yaml.

     For example, `kubectl apply` the object below

         ```yaml
         ---
         apiVersion: v1
         kind: ConfigMap
         metadata:
           name: configmap_name
         data:
           ops: |-
             some_random_ops
         ```

     and then use

         ```yaml
         operations:
           custom:
           - configmap_name
         ```

     in the values.yaml (or an equivalent `--set` option) as part of a
     kubecf deployment to include that ops file in the deployment.

     The [BOSH Development Workflow] is an example of its use.

     [BOSH Development Workflow]: bosh-release-development.md

  2. The second mechanism allows the specification of any custom BOSH
     property for any instancegroup and job therein.

     Just specifying

         ```yaml
         properties:
           instance-group-name:
             job-name:
               some-property: some-value
         ```

     in the values.yaml for the kubecf chart causes the chart to
     generate and use an ops file which applies the assignment of
     `some-value` to `some-property` to the specified instance group
     and job during deployment.

     An example of its use in Kubecf is limiting the set of test
     suites executed by the [CF acceptance tests](tests_cat.md).

Both forms of customization assume a great deal of familiarity on the
part of the developer and/or operator with the BOSH releases, instance
groups and jobs underlying the CF deployment manifest, i.e. which
properties exist, what changes to them mean and how they affect the
system.

### Patches

In SCF v2, the predecessor to kubecf, the [patches] scripts enabled
developers and maintainers to apply general patches to the sources of
a job (i.e. configuration templates, script sources, etc.) before that
job was rendered and then executed. At the core, the feature allows
the user to execute custom scripts during runtime of the job container
for a specific instance_group.

[Pre render scripts] are the equivalent feature of the CF operator.

[patches]: https://github.com/SUSE/scf/tree/develop/container-host-files/etc/scf/config/scripts/patches
[Pre render scripts]: https://github.com/cloudfoundry-incubator/cf-operator/blob/master/docs/from_bosh_to_kube.md#Pre_render_scripts

Kubecf makes use of this feature to fix a number of issues in the
deployment. The relevant patch scripts are found under the directory
`bosh/releases/pre_render_scripts`.

When following the directory structure explained by the
[README](pre-render-scripts.md), the bazel machinery for generating
the kubecf helm chart will automatically convert these scripts into
the proper ops files for use by the CF operator.

__Attention__ All patch scripts must be idempotent. In other words, it
must be possible to apply them multiple times without error and
without changing the result.

The existing patch scripts do this by checking if the patch is already
applied before attempting to apply it for real.

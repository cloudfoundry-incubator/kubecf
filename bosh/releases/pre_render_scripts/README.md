# Pre-render scripts

The directory __bosh/releases/pre_render_scripts__ contains scripts
added to the `quarks` property.

The structure of this directory is expected to be
`<instance_group>/<job>/<type>/<script>`, where `<type>` is one of

  - `jobs`
  - `bpm`
  - `ig_resolver`

This type details the exact location of where the patch executes.

## Background

[Pre render scripts] are kubecf's equivalent of its predecessors' (SCF
v2) [patches] scripts. They, like them, enable developers and
maintainers to apply general patches to the sources of a job
(e.g. configuration templates, script sources, etc.) before that job
was rendered and then executed.

At the core, the feature allows the user to execute custom scripts
during runtime of the job container for a specific instance_group.

[patches]: https://github.com/SUSE/scf/tree/develop/container-host-files/etc/scf/config/scripts/patches

[Pre render scripts]: https://github.com/cloudfoundry-incubator/cf-operator/blob/master/docs/from_bosh_to_kube.md#Pre_render_scripts

## Machinery

The parent and sibling directories (__bosh/releases__ and
__bosh/releases/generators__) will be used in __scripts/kubecf-build.sh__ to
convert the script files into the proper ops files for use by the CF operator,
as part of the overall generation of the kubecf helm chart.

It is this machinery which depends on the
`<instance_group>/<job>/<type>/<script>` structure noted above.

## Attention, Dangers

All patch scripts __must be idempotent__. In other words, it must be
possible to apply them multiple times without error and without
changing the result.

The existing patch scripts do this by checking if the patch is already
applied before attempting to apply it for real.

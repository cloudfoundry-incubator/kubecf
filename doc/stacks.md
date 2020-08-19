# Stacks

Kubecf can be configured with support for multiple stacks. A stack consists of the operating system rootfs and a list of buildpacks.

There are 2 stacks built in: The `cflinuxfs3` stack is defined by Cloud Foundry, and the `sle15` stack is based on SUSE Linux Enterprise.

The `install_buildpacks` list in `values.yaml` determines which stacks will be installed when the kubecf helm chart is deployed. The first stack in the list will be the default stack:

```
install_buildpacks: [sle15, cflinuxfs3]
```

## Stack definitions

A stack is defined in a single config file. A simplified example:

```
$ cat bclinux.yaml
stacks:
  bclinux:
    description: "BigCorp Linux-based filesystem"
    install_buildpacks: [bclang, java]

    release_prefix: bigcorp
    release_suffix: prod-buildpack

    releases:
      '$defaults':
        url: registry.bigcorp.com/kubecf
      bclinux:
        version: "1.5"
      bigcorp-bclang-prod-buildpack:
        version: "1.5.9.1"
      bigcorp-java-prod-buildpack:
        version: "4.32.1.1"
```

This describes the `bclinux` stack of BigCorp, supporting both their internal BigCorp language and Java.

The `install_buildpacks` list describes the order in which the buildpacks are added to Cloud Foundry. The names in here are the short forms of the buildpack names, e.g. `bclang` stands for `bclang_buildpack`.

The kubecf helm chart attempts to map release names to buildpack names automatically by stripping the optional `release_prefix` and `release-suffix`. The default `release-suffix` is "buildpack". If the remaining string then does not match the buildpack short name, then the release needs to include an explicit `buildpack` key:

```
    releases:
      external_ruby_builder:
        buildpack: ruby
```

## Modifying an existing stack

In addition to defining additional stacks, it is also possible to modify the built-in stacks:

```
stacks:
  cflinuxfs:
    install_buildpacks: [nodejs]
  sle15:
    install_buildpacks_prepend: [ourjava]
    install_buildpacks_append: [perl]
    releases:
      ourjava-buildpack:
        version:1.0.0
      suse-perl-buildpack:
        version: 5.28.1
```

This will remove all buildpacks execept for `nodejs` from the `cflinuxfs3` stack, and add 2 buildpacks to the `sle15` stack, prepending `ourjava` to the front of the list, and appending `perl` to the end.

## Eirini considerations

Currently Eirini supports only a single stack because the rootfs is embedded in the `bits-service` container image. For a custom stack to support Eirini it is therefore necessary that it also provides a custom `bits-service` image.

```
features:
  eirini:
    stack: bclinux

bits:
  global:
    images:
      bits_service: registry.bigcorp.com/kubecf/bits-service:24.33
```

The `features.eirini.stack` setting is used to validate the stack name when Eirini is enabled, to avoid deploying with an incompatible stack.

Note: the `bits.global.images` mechanism to change Eirini settings will change in the near future.

## Distribution

The simplest way to distribute a stack is via its YAML config file. It can then simply be used like this:

```
helm install kubecf "${KUBECF_CHART}" \
     --values bclinux.yaml --set install_stacks={bclinux} \
     --values local-config.yaml
```

If BigCorp has many users installing kubecf with their stack, they may want to distribute a modified helm chart including the stack. All that is required is dropping `bclinux.yaml` into the `config/` directory as `BCLINUX.yaml` and editing `values.yaml` to modify the `install_stacks` setting. Using an uppercase config filename makes sure it takes precedence over the builtin `eirini.yaml`, so can overwrite the `features.eirini.stack` value.

Unlike the `features.eirini.stack` setting, the `bits.global.images` can not be modified by a file dropped into `config/`. This should change once the Eirini config mechanism is updated.

## Requirements on rootfs and buildpack releases

There are a list of naming convention being used:

* All buildpacks are installed as `name_buildpack`. This doesn't make much sense, but is the way cf-deployment defines all the built-in stacks, and kubecf assumes this convention is used everywhere.

* There must be a release for that stack with exactly the same name as the stack (no prefix/suffix removal is applied here). This is the rootfs. Every other release must define a buildpack, either via the implicit name rules with prefix/suffix removal, or via a `buildpack` property.

* The rootfs must have a job called `$STACK-rootfs-setup` similar to [cflinuxfs3-release's cflinuxfs3-rootfs-setup](https://github.com/cloudfoundry/cflinuxfs3-release/blob/b47ca31/jobs/cflinuxfs3-rootfs-setup/templates/pre-start).

    In particular it need to include these lines, which kubecf needs to modify to work correctly:

    ```
    ROOTFS_DIR=$ROOTFS_PACKAGE/rootfs
    ROOTFS_TAR=$ROOTFS_PACKAGE/rootfs.tar
    ```

* Each buildpack release must store the buildpack as the only ZIP file inside a directory with the name `$SHORTNAME-buildpack-$STACK`, e.g. `/var/vcap/packages/ruby-buildpack-cflinuxfs3/something.zip`.


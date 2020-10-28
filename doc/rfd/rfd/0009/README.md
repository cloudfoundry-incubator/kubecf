---
authors: Victor Cuadrado <vcuadradojuan@suse.com>, Ettore Di Giacinto <edigiacinto@suse.de>
state: discussion
discussion: https://github.com/cloudfoundry-incubator/kubecf/pull/1495
---

# RFD 9: Specification for deployment and automation scripts

## Context


Developing a handful of loosely dependent Helm charts and building a Helm
distribution from them without creating an all-or-nothing "super-chart" is
difficult. One needs to make sure that deployment and automation scripts are
interoperable between charts, repos, repos' histories, and that they can be
reused and extended downstream as needed.

At the same time one needs to create, reuse, and extend test environments across
charts, and between upstream and downstream.

The following spec is an interface specification for sharing deployment and
automation scripts of Helm charts and utility applications.


## Specification

### Version `0.1`.

This spec defines an interface for Helm-based projects that allows them to share
and reuse deployment and automation scripts.

This spec does not focus on end-user usage, but strives to solve developer
problems. The projects implementing this spec are free to use Helm, Helmfiles,
or other means of deployment.

Definitions of *must*, *should*, *required*, etc, are as explained in
[rfc2119](https://tools.ietf.org/html/rfc2119).

Some behaviour has been purposedly left vague. When something is not concretely
specified, those implementing it have the freedom to implement it as they desire
(e.g: as of v0.1 path of the folder structure is not defined, so it can be
anywhere in the repo or resulting artifacts).

The interface consists in the following structure of folders and executables,
together with their expected use:

```
├── clean/*
├── clobber/*
├── chart/*
├── configure/*
│   └── patches/*
├── install/*
├── wait/*
├── include/*
│
├── one-offs/*
│
├── include/*
├── example-values/*
│
└── spec_ver
```

This structure as a whole may be published together with the Helm chart. This
can be for example as artifacts of a chart release, or present in the chart
repository, but it is recommended that these files are bundled inside of the chart:
this simplifies consumption downstream.

It is not recommended for targets to take arguments and options on execution besides the
expected default behaviour defined here.

Each target is required to be a folder (E.g: `install/`) containing executable
files starting with digits (E.g: `10_do-foo.sh`, `20_do-bar.rb`), with the
exception of the single targets in `one-offs/`, which must be a single
executable each.

Upon target call, all the executable files starting with digits will get
executed in alphanumeric order.
It is optional for the folder to contain other files/folders besides those
starting with digits. Those would not be automatically executed upon target
call (e.g: readme files, local include folders, etc).
  
Deployment and automation scripts must expose the following targets, with the
defined behaviour:

- `chart`: Obtains the latest public release of the chart at hand, and puts it
  already decompressed in `$pwd/$our-chart/chart/`. `$our-chart` being the name
  of the chart at hand (e.g: kubecf).

- `configure`: Outcome is a valid `$pwd/$our-chart/values.yaml` file for the
  chart at hand. This target accepts a list of alphanumerically ordered subsets
  of `values.yaml`, inside the folder `configure/patches/`, which get merged to
  output the final values.yaml. This allows for reuse of existing example
  values, and for downstream tools to inject their own yaml subsets as needed.

- `install`: Takes a `$pwd/$our-chart/values.yaml` and the chart contained in
  `$pwd/$our-chart/chart/` and installs the Helm Chart at hand. 

- `wait`: Will wait until deployment of the chart is up and running.

- `upgrade`: Takes a `$pwd/values.yaml` and a chart contained in
  `$pwd/$our-chart/chart/` and upgrades the Helm Chart at hand. The upgrade must
  work for both same version and different versions.

- `clean`: Performs a helm uninstall.

- `clobber`: Removes all possible objects created by any target from the cluster.
  (crds, webhooks…) leaving the cluster as it were before installation.
  Deletes `$pwd/$chart-name` at the end.

- `one-offs/*`: Helper targets. Follow the same rules as the rest of targets,
  except they may not be idempotent. E.g: `klog`, `login`, `smokes`, `cats`…
  
Each of these targets:

- Must assume that the deployment/testing env is already loaded, with access to
  kube, cf, helm operations.
- Must returns retcode `0` on success, `!= 0` if otherwise.
- Must consume and create files on `pwd` only.
- Must be idempotent: running it will give you the same result. E.g: calling
  `configure` several times with the same outputs gives you the same
  `values.yaml` as result. Calling `install` with the same `values.yaml` gives
  you the same deployment (that means that `install` must clean on its own).
- Must be isolated: implementation of `install` does not call on `configure`
  itself.
  They may, though, call shared implementation code in the `include` folder of
  their shared root path.
- Chart values must be only consumed from a yaml file, and not using `--set`.
- When useful, should save resulting artifacts of execution into
  `$pwd/artifacts`. E.g: `$pwd/artifacts/cats-run.log`


Apart from the targets, the following folders and files may be provided:


- `example-values/`: Contains a collection of examples of subsets of values
  yamls. E.g: `example-values/diego-ha-config.yaml`,
  `example-values/eirini-autoscaler-config.yaml`.

- `include/`: Contains possible reusable scripts to be used by 1 or more targets.

- `spec_ver`: file containing a string with the version of the spec that is being
  satisfied.


#### Example 1: KubeCF

Targets' file structure:
```
├── README.md
└── kubecf/
    ├── clean/
    │   └── 10_clean.sh
    ├── clobber/
    │   └── 10_clobber.sh
    ├── chart/
    │   └── 10_chart.sh
    ├── configure/
    │   ├── patches/
    │   │   ├── 01_kubecf_develop.yaml
    │   │   ├── 02_kubecf_loadbalancer_svc.yaml
    │   │   ├── 99_kubecf_config_override.yaml.disabled (made non exec)
    │   └── 10_merge.sh
    ├── install/
    │   ├── 10_install_quarks.sh
    │   ├── 20_install.kubecf.sh
    │   └── 25_workaround_asactor.sh
    ├── wait/
    │   └── 10_wait.sh
    ├── include/
    │   ├── bar
    │   ├── foo.rb
    │   ├── func.sh
    │   └── readme.md
    └── one-offs/
        ├── klog.sh
        └── upgrade.sh
```


Resulting "Build" folder of the targets after installing the kubecf chart:

```
└── kubecf/
    ├── values.yaml
    ├── chart/
    │   ├── Chart.yaml
    │   ├── assets/*
    │   ├── templates/*
    │   ├── config/*
    │   ├── imagelist.txt
    │   └── …
    └── artifacts/
        └── cats-run.log
```


## Consequences

Projects that decide to adopt this spec must provide the specified
targets and interface. They are free to call the executables as they see fit,
create their own targets to group them, have $pwd be wherever (e.g:
`./output/`), etc.

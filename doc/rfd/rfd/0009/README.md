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

### User stories

#### Direct downstream developer

As a downstream developer of a project that directly depends on kubecf helm
chart, I need to have an up-to-date way of deploying, testing, and automating my
modifications, without needing to pursue upstream and keep daily track of
changes in upstream automation.

If kubcf chart implements this spec, I will have those tagged together with their
release.
I will reuse automation scripts such as test runs, airgap configurations,
private registry settings, etc.
Also it will be possible for me to inject workarounds that I may
upstream later.

My project also depends on minibroker chart, quarks chart, and in the future on helm
caps-registry chart. I, as downstream, need to come with a way for to test and
automate them together. The more charts that implement the spec, the more I can
rely on their example-values and automation.


#### Parallel upstream developer

I am a developer of kubecf chart. My chart doesn't directly depend on stratos
chart or caps-registry chart. But sometimes they develop automation that I could reuse.
If they implement this spec, I will have access to their automation in simple,
pull-way manner.

## Specification

### Version `0.1`.

This spec defines an interface for Helm-based projects that allows them to share
and reuse deployment and automation scripts.

This spec does not focus on end-user usage, but strives to solve developer
problems. The projects implementing this spec are free to use Helm, Helmfiles,
or other means of deployment.

Definitions of *must*, *should*, *required*, etc, are as explained in
[rfc2119](https://tools.ietf.org/html/rfc2119).

Some behaviour has been purposely left vague. When something is not concretely
specified, those implementing it have the freedom to implement it as they desire
(e.g: as of v0.1 path of the folder structure is not defined, so it can be
anywhere in the repo or resulting artifacts).

The interface consists in targets that can be called and perform their defined
action, together with helper files and examples of configuration for the charts.

Those targets and files must be in the following structure of folders and executables:

```
├── uninstall/*
├── clobber/*
├── chart/*
├── configure/*
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

Each target is required to be a folder (E.g: `install/`) containing executable
files starting with digits (E.g: `10_do-foo.sh`, `20_do-bar.rb`). Targets
defined in the `one-offs/` folder also follow this structure.

Upon target call, all the executable files starting with digits will get
executed in alphanumeric order.
It is optional for the folder to contain other files/folders besides those
starting with digits. Those would not be automatically executed upon target
call (e.g: readme files, local include folders, etc).

Each of these targets:

- Must assume that the deployment/testing env is already loaded, with access to
  kube, cf, helm operations.
- Must return retcode `0` on success, `!= 0` if otherwise.
- Must consume and create files on `pwd` only.
- Must be idempotent: running it will give you the same result. E.g: calling
  `configure` several times with the same outputs gives you the same
  `values.yaml` as result. Calling `install` with the same `values.yaml` gives
  you the same deployment.
- Must be isolated: E.g; implementation of `install` does not call on `configure`
  itself.
  They may, though, call shared implementation code in the `include` folder of
  their shared root path.
- Chart values must be only consumed from yaml files, and not using `--set`.
- When useful, should save resulting artifacts of execution into
  `$pwd/artifacts`. E.g: `$pwd/artifacts/cats-run.log`

It is not recommended for targets to take arguments and options on execution
besides the expected default behaviour defined here.
  
Deployment and automation scripts must expose the following targets, with the
defined behaviour:

- `chart`: Obtains the latest public release of the chart at hand, and puts it
  already decompressed in `$pwd/$our-chart/chart/`. `$our-chart` being the name
  of the chart at hand (e.g: kubecf). While this target is required to be
  implemented, the intent is that test runners may decide to not call it and
  drop themselves the chart under test in `$pwd/$our-chart/chart/`.

- `configure`: Generates any config values that cannot be taken from the
  `example-values/` folder as they aren't there. Normally, this will be
  cluster-dependent configs. For that, it can read the following keys from a
  configmap named `cap-values` in namespace kube-system:
  * `domain`: Either a subdomain or a root domain, to be used on the deployment.
  * `services`: Either `ingress`, `lb`, `hardcoded`.
  * `public-ip`: Public ip of the cluster, in case `services == hardcoded`.
    Normally used with a magic DNS service.
  * `ingress-cert` and `ingress-key`: TLS cert and key for ingress.
  Outcome is a valid set of yaml files in `$pwd/$our-chart/values/` folder.
  This allows for reuse of existing example values, and for downstream tools to
  inject their own yaml subsets as needed.

- `install`: Takes the config values in the `$pwd/$our-chart/values/` folder and
  the chart contained in `$pwd/$our-chart/chart/` and installs the Helm Chart at
  hand.

- `wait`: Waits until deployment of the chart is up and ready.

- `upgrade`: Takes the config values in `$pwd/$our-chart/values/` folder and a
  chart contained in `$pwd/$our-chart/chart/` and upgrades the Helm Chart at
  hand. The implementation must work for both same-version upgrades and
  different-version upgrades.

- `uninstall`: Performs a helm uninstall.

- `clobber`: Removes all possible objects created by any target from the cluster.
  (crds, webhooks…) leaving the cluster as it were before installation.
  Deletes `$pwd/$chart-name` at the end.

- `one-offs/*`: Helper targets. Follow the same rules as the rest of targets,
  except they may not be idempotent. E.g: `klog`, `login`, `smokes`, `cats`…
  
Apart from the targets, the following folders and files must be provided:

- `example-values/`: Contains examples of possible config values. Separated into
  2 folders:
  * `example-values/overlapped/`: examples which cannot be used at the same
  time. E.g: `diego.yaml`, `eirini.yaml`.
  * `example-values/subset/`: examples of subsets of configuration, which can be
    used together. E.g: `private-registry.yaml`, `testsuites-config.yaml`, `ha.yaml`,
    `ingress.yaml`.

- `imagelist.txt`: Lists all needed container images, fully qualified with
    repository, org, name and tag. Useful for airgap and private registry
    installations.

- `include/`: Contains possible reusable scripts to be used by 1 or more targets.

- `spec_ver`: file containing a string with the version of the spec that is being
  satisfied.


#### Example 1: KubeCF

Targets' file structure:
```
├── README.md
└── kubecf/
    ├── uninstall/
    │   └── 10_uninstall.sh
    ├── clobber/
    │   └── 10_clobber.sh
    ├── chart/
    │   └── 10_chart.sh
    ├── configure/
    │   ├── patches/
    │   │   └── 02_kubecf_loadbalancer_svc.yaml
    │   └── 10_create_cluster-dependent_values.sh
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
    ├── one-offs/
    │   ├── klog/
    │   │   └── 01_klog.sh
    │   ├── upgrade/
    │   │   └── 01_upgrade.sh
    │   ├── login/
    │   │   └── 01_login.sh
    │   ├── smokes/
    │   │   └── 01_smokes.rb
    │   ├── cats/
    │   │   └── 01_cats.sh
    │   └── readme.md
    └── example-values/
        ├── overlapped/
        │   ├── diego.yaml
        │   └── eirini.yaml
        └── subset/
            ├── ha.yaml
            ├── autoscaler.yaml
            ├── ingress.yaml
            ├── testsuites-config.yaml
            └── private-registry.yaml
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

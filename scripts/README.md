# KubeCF support scripts

## Overview

The `scripts/` directory contains scripts to support KubeCF development, setup
kubernetes via `kind` or `minikube`, and build, deploy, and test KubeCF.

All scripts expect to be invoked from the root of the `kubecf` git repository.
It contains a `Makefile` that can be used to launch them (tab-completion).

Many scripts will only work from a git checkout because the product versioning
needs to look up tags.

## Shared Configuration

The script use a common framework via `source scripts/include/setup.sh`. It
provides some shared configuration settings:

### `XTRACE`

Setting `XTRACE=1 make ...` will turn on bash tracing for the scripts. This
is mostly a debugging tool when the scripts fail, and the cause isn't obvious.

### `PINNED_TOOLS`

Each script declares all external tools it is using with a command like this:

```bash
require_tools cf kubectl
```

Minimum tool versions, and potential download sources are defined in `./scripts/tools`.
It contains a [README](tools/README.md) that explains the various ways to
define them.

By default the scripts will accept the minimum or any later version that
can be invoked via `PATH` and will only download and install a newer version
if the local version is missing or too old.

If `PINNED_TOOLS` is set to a non-empty value, then an exact version match is
required.

### `TOOLS_DIR`

Downloaded tools will be installed into `TOOLS_DIR`, which defaults to
`./output/bin`. This directory will always be at the front of the `PATH`
when these scripts are executed.

## Index of scripts


### Development

#### ./scripts/tools-install.sh

This script installs the pinned version of all configured tools into `TOOLS_DIR`
unless the installed version is already an exact match.

#### ./scripts/tools-versions.sh

List all configured tools and their current versions.

When running with `PINNED_TOOLS` set to a non-empty value, it will throw an
error for each [installable tool](tools/README.md#installable-tools) that
is missing, is not installed with the required version, or is not installed
in the `TOOLS_DIR`.

#### ./scripts/version.sh

Prints the current KubeCF version to STDOUT. It is used by `kubecf-build` and
`kubecf-bundle` to create default output filenames, and is also available to
CI. The version will be `0.0.0` on the master branch and `x.y.z` on a
`release-x.y` release branch.

#### ./dev/helm/update_subcharts.sh

Subcharts of `kubecf` are declared in `chart/requirements.yaml`.
Running `update_subcharts.sh` after updating the `requirements.yaml` will
fetch updated subcharts from their helm repos and unpacks them under the
`chart/charts` directory, so the diff to the previous version
becomes a part of the git commit.

#### ./scripts/helmlint.sh

Run `helm lint` against the appropriate files.

#### ./scripts/shellcheck.sh

Run `shellcheck` against the appropriate files.

#### ./scripts/yamllint.sh

Run `yamllint` against the appropriate files.


### Build

#### ./scripts/kubecf-build.sh

Builds the `kubecf` helm chart. This includes the `imagelist.txt` inventory of
all referenced container images and the `sample-values.yaml` version of the
commented out `values.yaml`.

The default output filename will be `output/kubecf-${VERSION}.tgz`, with `$VERSION`
determined by `./scripts/version.sh`. An alternate output filename can be set (e.g.
for the benefit of CI) via:

```bash
TARGET_FILE=out/kubecf.tgz make kubecf-build
```

#### ./scripts/kubecf-bundle.sh

Creates a "bundle" tarball containing both the right version of `cf-operator.tgz`
and a `kubecf_release.tgz` built via `../scripts/kubecf-build.sh`.

The default output filename will be `output/kubecf-bundle-${VERSION}.tgz`, but
can be overridden by setting the `TARGET_FILE` variable.

### Kube dev environments

There are scripts to setup and teardown local kubernetes clusters for
development using either `kind` or `minikube`.

The `kind` version does not work for deploying KubeCF with Diego on macOS
because the Docker for Mac host VM doesn't support either btrfs or xfs.

The `xxx-start.sh` scripts will update the local `KUBECONFIG` with a context for
the new cluster, and select it as the current context.

The scripts support additional variable to configure the kube environment; take
a look at the source to see what is supported.

#### ./scripts/kind-start.sh

#### ./scripts/kind-delete.sh

#### ./scripts/minikube-start.sh

#### ./scripts/minikube-delete.sh


### Run

The scripts to run and test KubeCF can be used with any compatible kube
environment set up as the current kube config. It is not limited to the `kind`
and `minikube` setups provided by the scripts above.

#### ./scripts/cf-operator-apply.sh

Creates the cf-operator namespace and deploys the required version of
`quarks-operator`. Currently you have to wait manually until the operator pods
are running before deploying the `kubecf` chart.

#### ./scripts/kubecf-apply.sh

Deploys the `kubecf` chart. If the `CHART` environment variable is not set then this script will first run `./scripts/kubecf-build.sh` to make certain that the chart is up-to-date with regard to the current state of the working directory. Otherwise it will deploy the chart specified by `CHART`.

Helm configuration variables can be set in a YAML file pointed to by `VALUES`.

Some common features can be enabled by setting their configuration variable
to a non-empty value: `FEATURE_AUTOSCALER`, `FEATURE_EIRINI`, and
`FEATURE_INGRESS`.

#### ./scripts/cf-login.sh

`cf-login` can be run once the cluster is ready and all pods are running.  It
performs a `cf login` with the correct username, password, and API endpoint.

#### ./scripts/kubecf-delete.sh

Delete the `kubecf` release and also removes all PVCs so that a fresh deployment
can be run again afterwards.

#### ./scripts/cf-operator-delete.sh

Oops, this script should exist, but currently doesn't.

### Test

#### ./scripts/test.sh

This script starts a test job. By default it runs `smoke` tests, but can be
configured using the `TEST` variable to run `acceptance` (CATS), `brain`,
`smoke` (default) or `sync-integration` (SITS) as well.

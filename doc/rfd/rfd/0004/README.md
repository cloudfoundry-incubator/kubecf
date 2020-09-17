---
authors: Vlad Iovanov <VIovanov@suse.com>
state: published
discussion: https://github.com/cloudfoundry-incubator/kubecf/pull/1074
---

# RFD 4 upgrade testing methodology when releasing

## Context

One of the goals of the KubeCF project is to offer a smooth experience when it comes to upgrading Cloud Foundry deployments.
That means any user operating a KubeCF deployment should:

- be able to easily identify which versions they can upgrade to.
- upgrade using documented procedures.
- have confidence that the exact version upgrade they are performing has been tested by the KubeCF team.

## Decision

- KubeCF is not allowed to have minor releases for version `X.y.z` if `X+1` has been released (only patch releases)
- for a version `X.y.z`, the upgrade path must be tested for:
  - the previous `X.*.*` release
  - the latest `X-1.*.*` release

Therefore, for downstream projects, assuming they don't release as often as KubeCF, we recommend that the following rules should be in place:

- there should be a release for each major KubeCF release (as upgrades skipping a major KubeCF release are not supported)
- for a version `X.y.z`, the upgrade path must be tested for:
  - the previous `X.*.*` release
- if a version `X.y.z` cannot be upgraded from `X.y-1.t`, a new version `X.y-1.t+1` must be created from a known upgradeable path in KubeCF.

![diagram](https://docs.google.com/drawings/d/e/2PACX-1vSK_9XqNiLbpzrQGnJ9BISSQq8DKTeE3yDjszyJfC7BdPuABO0QbAMMZruEoMnTFwhhtzCEGeXowqmh/pub?w=1037&h=918)

## Consequences

- we only allow patch releases for old major releases
- more scenarios must be tested in our pipelines to ensure the upgrade paths work.
- accurately using semver for KubeCF is important
- should enforce [the RFD](https://github.com/cloudfoundry-incubator/kubecf/blob/master/doc/rfd/0002/README.md)

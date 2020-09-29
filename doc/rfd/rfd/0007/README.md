---
authors: Jaime Gomes <jaime.gomes@suse.com>
state: discussion
discussion: https://github.com/cloudfoundry-incubator/kubecf/pull/1399
---

# RFD 7 Deployment and Upgrade Benchmark

## Introduction

### Motivation

Currently, we do not have any gather data that can corroborate with some eye evidence that
deployment times of KubeCF are increasing and upgrades are not argument supported in the next
releases.

### Goal

Be able to measure and collect time metrics during a fresh deployment and between upgrades, on each
component present on KubeCF.

With the time data collected, both upstream projects and downstream product teams can investigate
if there're optimizations that can lead to a better and more fasten deployments that will support a
better user experience in future releases.

## Proposed solution

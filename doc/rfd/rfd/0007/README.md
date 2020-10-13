---
authors: Jaime Gomes <jaime.gomes@suse.com>
state: draft
discussion: 
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

### Type of Deployments

1. Eirini enabled:
1.1 High availability
2. Diego enabled:
2.1 High availability


## Possible solution(s)

### Solution A

### Metrics streamer

A k8s native component like [kube-state-metrics[(https://github.com/kubernetes/kube-state-metrics)]
that is deploable on a pod and it listens the k8s API server and generates metrics. It is
important that it can be configurable regarding the namespace or namespaces that can collect from
and acceptable from a security perspective.

### Metrics collector

Promotheus what else?

## Proposed Solution

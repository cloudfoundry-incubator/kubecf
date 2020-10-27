---
authors: Jaime Gomes <jaime.gomes@suse.com>
state: draft
discussion: 
---

# RFD 7 Deployment and Upgrade Benchmark

## Introduction

### Motivation

Currently, we do not have any data that can corroborate with some eye evidence that deployment times
of KubeCF are increasing between releases.

### Goal

Be able to measure and collect time metrics during a fresh deployment and between upgrades, on each
component (pod) present on KubeCF.

With the time data collected, both upstream projects and downstream product teams can investigate
if there're optimizations that can lead to a better and more fasten deployments that will support a
better user experience in future releases.

### Metric(s) to collect

| Resource | Metric Pseudo Name              | Condition                 | Namespace |
| -------- | ------------------------------- | ------------------------- | --------- |
| Job      | kube_job_status_completion_time | kube_job_status_succeeded | kubecf    |
| Pod      | kube_pod_completion_time        | kube_pod_status_ready     | kubecf    |

## Possible solution(s)

### Solution A

### Metrics streamer

A k8s native component like [kube-state-metrics[(https://github.com/kubernetes/kube-state-metrics)]
that is deployable on a pod, monitors the k8s API server, and generates metrics. It is
important that it can be configurable regarding the namespace or namespaces that can collect from
and acceptable from a security perspective.

### Metrics collector

Prometheus?

## Proposed Solution

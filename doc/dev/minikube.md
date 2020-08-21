# Kubecf deployment via Minikube/Bazel + Operator/Bazel + Kubecf/Bazel (Checkout)

The intended audience of this document are developers wishing to
contribute to the Kubecf project.

Here we explain how to deploy Kubecf locally using:

  - Minikube to manage a local Kubernetes cluster.
  - A cf-operator pinned with Bazel.
  - Kubecf built and deployed from the sources in the current checkout.

## Minikube

Minikube is one of several projects enabling the deployment,
management and tear-down of a local Kubernetes cluster.

The Kubecf Makefile contains targets to deploy and/or tear-down
a Minikube-based cluster. Using these has the advantage of using a
specific version of Minikube. On the other side, the reduced
variability of the development environment is a disadvantage as well,
possibly allowing portability issues to slide through.

| Operation  | Command                |
|------------|------------------------|
| Deployment | `make minikube-start`  |
| Tear-down  | `make minikube-delete` |
|            |                        |

### Attention, Dangers

Minikube edits the Kubernetes configuration file referenced by the
environment variable `KUBECONFIG`, or `~/.kube/config`.

To preserve the original configuration either make a backup of the
relevant file, or change `KUBECONFIG` to a different path specific to
the intended deployment.

### Advanced configuration

The local [Minikube Documentation](../kube/minikube.md) explains the
various environment variables which can be used to configure the
resources used by the cluster (CPUs, memory, disk size, etc.) in
detail.

## cf-operator

The [cf-operator] is the underlying generic tool to deploy a (modified)
BOSH deployment like Kubecf for use.

[cf-operator]: https://github.com/cloudfoundry-incubator/cf-operator

It has to be installed in the same kube cluster Kubecf will be deployed to.

### Deployment and Tear-down

The Kubecf Makefile contains targets to deploy and/or tear-down
cf-operator:

| Operation  | Command                  |
|------------|--------------------------|
| Deployment | `make cf-operator-apply` |
| Wait       | `make cf-operator-wait`  |

## Kubecf

With all the prequisites handled by the preceding sections it is now
possible to build and deploy kubecf itself.

### System domain

The system domain gets set up as part of `make kubecf-apply`.

### Deployment and Tear-down

The Kubecf Bazel workspace contains targets to deploy and/or tear-down
kubecf from the sources:

| Operation  | Command              |
|------------|----------------------|
| Deployment | `make kubecf-apply`  |
| Tear-down  | `make kubecf-delete` |
|            |                      |

In this default deployment kubecf is launched without Ingress, and
uses the Diego scheduler.

### Access

Accessing the cluster from outside of the minikube VM requires
[ingress](#ingress) to be set up correctly.

To access the cluster after the cf-operator has completed the
deployment and all pods are active invoke:

```sh
cf api --skip-ssl-validation "https://api.$(minikube ip).xip.io"

# Copy the admin cluster password.
acp=$(kubectl get secret \
        --namespace kubecf kubecf.var-cf-admin-password \
        -o jsonpath='{.data.password}' \
        | base64 --decode)

# Use the password from the previous step when requested.
cf auth admin "${acp}"
```

### Advanced Topics

#### Diego vs Eirini

Diego is the standard scheduler used by kubecf to deploy CF
applications. Eirini is an alternative to Diego that follows a more
Kubernetes native approach, deploying the CF apps directly to a
Kubernetes namespace.

To activate this alternative, add a file matching the pattern
`*values.yaml` to the directory __dev/kubecf__ and containing

```yaml
features:
  eirini:
    enabled: true
```

before deploying kubecf.

#### Ingress

By default, the cluster is exposed through its Kubernetes services.

To use the NGINX ingress instead, it is necessary to:

  - Install and configure the NGINX Ingress Controller.
  - Configure Kubecf to use the ingress controller.

This has to happen before deploying kubecf.

##### Installation of the NGINX Ingress Controller

```sh
helm install stable/nginx-ingress \
  --name ingress \
  --namespace ingress \
  --set "tcp.2222=kubecf/kubecf-scheduler:2222" \
  --set "tcp.<services.tcp-router.port_range.start>=kubecf/kubecf-tcp-router:<services.tcp-router.port_range.start>" \
  ...
  --set "tcp.<services.tcp-router.port_range.end>=kubecf/kubecf-tcp-router:<services.tcp-router.port_range.end>" \
  --set "controller.service.externalIPs={$(minikube ip)}"
```

The `tcp.<port>` option uses the NGINX TCP pass-through.

In the case of the `tcp-router` ports, one `--set` for each port is required, starting with
`services.tcp-router.port_range.start` and ending with `services.tcp-router.port_range.end`. Those
values are defined on the `values.yaml` file with default values.

The last flag in the command above assigns the external IP of the
cluster to the Ingress Controller service.

##### Configure kubecf

Place a file matching the pattern `*values.yaml` into the directory
__dev/kubecf__ and containing

```yaml
features:
  ingress:
    enabled: true
```

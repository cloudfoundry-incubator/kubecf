## Public access to the cluster

There are two options for accessing the cluster publicly:

- Via a Kubernetes service.
- Via NGINX Ingress Controller.

### Option 1: Configuring the Kubernetes service

This is the default option. It defaults to a service of type LoadBalancer. In order to configure it
differently, check the `service` key under the `values.yaml` file on the chart.

### Option 2: NGINX Ingress Controller

/helm/

#### Install NGINX Ingress Controller

```sh
helm install stable/nginx-ingress \
  --name ingress \
  --namespace ingress
```

**For Minikube**

Pass the flag `--set "controller.service.externalIPs={$(minikube ip)}"` to the `helm install` in
order to assign the external IP to the Ingress Controller service.

## Install Kubecf

### Apply the chart

If you opted to use the NGINX Ingress Controller for the public access to the cluster, set the
property `features.ingress.enabled` to `true`.

```sh
bazel run //dev/kubecf:apply
```

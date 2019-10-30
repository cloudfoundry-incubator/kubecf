# Installing SCF

## Prerequisites

You need to have [cf-operator] installed in your Kubernetes cluster (currently
tip of `master` is required).

[cf-operator]: https://github.com/cloudfoundry-incubator/cf-operator

### Build cf-operator

Build the operator image from a `cf-operator` checkout:

```sh
SAVE_TARBALL=true make build-image
```

### Install cf-operator

Load the cf-operator, depending on if you're using `kind` or `minikube`:

#### When using `kind`

```sh
kind load image-archive --name scf binaries/cf-operator-image.tgz
```

#### When using `minikube`

```sh
(eval $(minikube docker-env) ; docker load --input binaries/cf-operator-image.tgz)
```

#### Install cf-operator after loading

Run the following commands to run `cf-operator` _locally_, taking to your
kubernetes cluster:

```sh
kubectl create namespace scf

# Get the default network device, being the word after "dev".
DEFAULT_NET_DEVICE="$(ip route list 0/0 | perl -n -e '/\bdev\s+(\S+)/ && print $1')"

# Get the IP address of that device.
DEFAULT_NET_ADDR="$(ip -4 -o addr show dev "${DEFAULT_NET_DEVICE}" | perl -n -e '/\binet\s+([^\/]+)/ && print $1')"

# Deploy cf-operator.
CF_OPERATOR_WEBHOOK_SERVICE_HOST="${DEFAULT_NET_ADDR}" CF_OPERATOR_NAMESPACE=scf SKIP_IMAGE=true make up
```

## Public access to the cluster

There are two options for accessing the cluster publicly:

- Via a Kubernetes service.
- Via NGINX Ingress Controller.

### Option 1: Configuring the Kubernetes service

This is the default option. It defaults to a service of type LoadBalancer. In order to configure it
differently, check the `service` key under the `values.yaml` file on the chart.

### Option 2: NGINX Ingress Controller

#### Create the Helm Tiller service account and give it cluster-admin rights

(WARNING! THIS IS FOR DEVELOPMENT ONLY)

```sh
kubectl create serviceaccount tiller \
  --namespace kube-system

kubectl create clusterrolebinding tiller \
  --clusterrole cluster-admin \
  --serviceaccount=kube-system:tiller
```

#### Initialize Helm Tiller

```sh
helm init --upgrade --service-account tiller --wait
```

#### Install NGINX Ingress Controller

```sh
helm install stable/nginx-ingress \
  --name ingress \
  --namespace ingress
```

**For Minikube**

Pass the flag `--set "controller.service.externalIPs={$(minikube ip)}"` to the `helm install` in
order to assign the external IP to the Ingress Controller service.

## Install SCF

### Set the system_domain

#### When using Minikube

```sh
echo "system_domain: $(minikube ip).xip.io" \
  > "$(bazel info workspace)/dev/scf/system_domain_values.yaml"
```

#### When using Kind

```sh
echo "system_domain: scf.suse.dev" \
  > "$(bazel info workspace)/dev/scf/system_domain_values.yaml"
```

### Apply the chart

If you opted to use the NGINX Ingress Controller for the public access to the cluster, set the
property `features.ingress.enabled` to `true`.

```sh
bazel run //dev/scf:apply
```

Refer to [Accessing the SCF cluster](./accessing.md) for the next steps.

## Delete SCF

```sh
bazel run //dev/scf:delete
```

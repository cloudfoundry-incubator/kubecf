# SCF

The targets under `scf` are used to apply the rendered Helm template to a Kubernetes cluster.
Any `*values.yaml` files under this directory are ignored by git, but used by Bazel to render the
SCF chart before applying to the cluster with kubectl.

## Prerequesites

You need to have [cf-operator] installed in your Kubernetes cluster (currently
tip of `master` is required).

[cf-operator]: https://github.com/cloudfoundry-incubator/cf-operator

### Building cf-operator

Build the operator image from a `cf-operator` checkout:

```sh
SAVE_TARBALL=true make build-image
```

### Installing cf-operator

Load the cf-operator, depending on if you're using `kind` or `minikube`:

#### When using `kind`

```sh
kind load image-archive --name scf binaries/cf-operator-image.tgz
```

#### When using `minikube`

```sh
(eval $(minikube docker-env) ; docker load --input binaries/cf-operator-image.tgz)
```

#### Installing cf-operator after loading

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

## Apply

Run:

```sh
bazel run //dev/scf:apply
```

## Delete

Run:

```sh
bazel run //dev/scf:delete
```

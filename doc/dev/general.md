# Kubecf deployment via any Kube + Operator/Helm + Kubecf/Helm

The intended audience of this document are developers wishing to
contribute to the Kubecf project.

Here we explain how to deploy Kubecf using:

  - A generic kubernetes cluster.
  - A released cf-operator helm chart.
  - A released kubecf helm chart.

## Kubernetes

In contrast to other recipes we are not set on using a local
cluster. Any kubernetes cluster will do. Assuming that the following
requirements are met:

  - Presence of a default storage class (provisioner)

  - For use with a diego-based kubecf (default) a node OS with XFS
    support.

      - For GKE using the option `--image-type UBUNTU` with the
        `gcloud beta container` command selects such an OS.

This can be any of GKE, AKS, EKS, etc.

Note that how to deploy and tear-down such a cluster is outside of the
scope of this recipe.

## cf-operator

The [cf-operator] is the underlying generic tool to deploy a (modified)
BOSH deployment like Kubecf for use.

[cf-operator]: https://github.com/cloudfoundry-incubator/cf-operator

It has to be installed in the same kube cluster Kubecf will be deployed to.

Here we are not using development-specific dependencies like bazel,
but only generic tools, i.e. `kubectl` and `helm`.

[Installing and configuring Helm](helm.md) is the same regardless of
the chosen foundation, and assuming that the cluster does not come
with helm pre-installed (cluster-side).

### Deployment and Tear-down

```shell
helm install --name cf-operator \
     --namespace cfo \
     --set "operator.watchNamespace=kubecf" \
     https://s3.amazonaws.com/cf-operators/helm-charts/cf-operator-v0.4.1%2B92.g77e53fda.tgz
```

In the example above version 0.4.1 of the operator was used.  Look
into the `cf_operator` section of the toplevel `def.bzl` file to find
the version of the operator validated against the current kubecf
master.

Note how the namespace the operator is installed into (`cfo`) differs
from the namespace the operator is watching for deployments (`kubecf`).

This form of deployment enables restarting the operator, because it is
not affected by webhooks. It further enables the deletion of the
Kubecf deployment namespace to start from scratch, without redeploying
the operator itself.

Tear-down is done with a standard `helm delete ...` command.

## Kubecf

With all the prequisites handled by the preceding sections it is now
possible to build and deploy kubecf itself.

This again uses helm and a released helm chart.

### Deployment and Tear-down

```
helm install --name kubecf \
     --namespace kubecf \
     https://scf-v3.s3.amazonaws.com/scf-3.0.0-82165ef3.tgz \
     --set "system_domain=kubecf.suse.dev"
```

In this default deployment kubecf is launched without Ingress, and
uses the Diego scheduler.

Tear-down is done with a standard `helm delete ...` command.

### Access

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
cf auth -u admin -p "${acp}"
```

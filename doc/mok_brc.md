# Kubecf deployment via Minikube/Bazel + Operator/Release + Kubecf/Checkout

The intended audience of this document are developers wishing to
contribute to the Kubecf project.

Here we explain how to deploy Kubecf locally using:

  - Minikube to manage a local kubernetes cluster.
  - Helm for rendering kube templates.
  - A cf-operator released as a helm chart.
  - Kubecf built and deployed from the sources in the current checkout.

## Minikube

Minikube is one of several projects enabling the deployment,
management and teardown of a local kubernetes cluster.

The Kubecf bazel workspace contains targets to deploy and/or tear down
a minikube-based cluster. Using these has the advantage of using a
specific version of minikube. On the other side, the reduced
variability of the development environment is a disadvantage as well,
possibly allowing portability issues to slide through.

|Operation	|Command				|
|---		|---					|
|Deployment	| `bazel run //dev/minikube:start`	|
|Tear down	| `bazel run //dev/minikube:delete`	|

### Attention, Dangers

Minikube edits the kubernetes configuration file referenced by the
environment variable `KUBECONFIG`, or `~/.kube/config`.

To preserve the original configuration either make a backup of the
relevant file, or change `KUBECONFIG` to a different path specific to
the intended deployment.

### Advanced configuration

The local [Minikube Documentation](../dev/minikube/README.md) explains
the various environment variables which can be used to configure the
resources used by the cluster (cpus, memory, disk size, etc.) in
detail.

## Helm

The previous step sets up only a bare cluster. For many operations we
will need/use the Helm cli to deploy, inspect, manage and destroy
complex deployments specified as Helm charts.

[Installing and configuring Helm](helm.md) is the same regardless of
the chosen foundation.

## cf-operator

The [cf-operator] is the underlying generic tool to deploy a (modified)
BOSH deployment like Kubecf for use.

[cf-operator]: https://github.com/cloudfoundry-incubator/cf-operator

It has to be installed in the same kube cluster Kubecf will be deployed to.

For simplicity, it will be installed from a released helm chart:

```shell
helm install --name cf-operator \
     --namespace cfo \
     --set "operator.watchNamespace=kubecf" \
     https://s3.amazonaws.com/cf-operators/helm-charts/cf-operator-v0.4.1%2B92.g77e53fda.tgz
```

In this example version 0.4.1 of the operator was used.

Note how the namespace the operator is installed into (`cfo`) differs
from the namespace the operator is watching for deployments (`kubecf`).

This form of deployment enables restarting the operator, because it is
not affected by webhooks. It further enables the deletion of the
Kubecf deployment namespace to start from scratch, without redeploying
the operator itself.

## Kubecf

With all the prequisites handled by the preceding sections it is now
possible to build and deploy kubecf itself.

### System domain

The main configuration to set for kubecf is its system domain.
For the minikube foundation we have to specify it as:

```sh
echo "system_domain: $(minikube ip).xip.io" \
  > "$(bazel info workspace)/dev/scf/system_domain_values.yaml"
```

### Deployment and Teardown

The Kubecf bazel workspace contains targets to deploy and/or tear down
kubecf from the sources:

|Operation	|Command			|
|---		|---				|
|Deployment	| `bazel run //dev/scf:apply`	|
|Tear down	| `bazel run //dev/scf:delete`	|

In this default deployment kubecf is launched without Ingress, and
uses the Diego scheduler.

### Access

To access the cluster after the cf-operator has completed the
deployment and all pods are active invoke:

```sh
cf api --skip-ssl-validation "https://api.$(minikube ip).xip.io"

# Copy the admin cluster password.
acp=$(kubectl get secret \
	      --namespace scf scf.var-cf-admin-password \
	      -o jsonpath='{.data.password}' \
	      | base64 --decode)

# Use the password from the previous step when requested.
cf auth -u admin -p "${acp}"
```

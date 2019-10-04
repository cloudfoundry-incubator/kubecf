# Install SCFv3 release

## Prepare the cluster

### minikube

We need more disk space in minikube, otherwise pods will get evicted and the deployment will be in a constant loop.

Create the cluster with:

    minikube start --memory=12000mb --cpus=4 --disk-size=40gb --kubernetes-version v1.14.1


### GKE

At least for Diego we need a node OS with XFS support.
The `--image-type UBUNTU` selects an OS with XFS support.

Create the cluster like this:

```
project=scfv3
clustername=scfv3-test
gcloud beta container --project "$project" clusters create "$clustername" \
      --zone "europe-west4-a" --no-enable-basic-auth --cluster-version "1.12.8-gke.10" \
      --machine-type "custom-6-13312" --image-type "UBUNTU" --disk-type "pd-standard" \
      --disk-size "100" --metadata disable-legacy-endpoints=true \
      --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
      --preemptible --num-nodes "1" --enable-cloud-logging --enable-cloud-monitoring \
      --enable-ip-alias --network "projects/$project/global/networks/default" \
      --subnetwork "projects/$project/regions/europe-west4/subnetworks/default" \
      --default-max-pods-per-node "110" --addons HorizontalPodAutoscaling,HttpLoadBalancing \
      --enable-autoupgrade --enable-autorepair --no-shielded-integrity-monitoring
```

## Install Helm

Install Helm with RBAC, this involves creating the role first:

```
kubectl create -f <( cat <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: tiller
    namespace: kube-system
EOF
)

helm init --upgrade --service-account tiller --wait
```

## Install CF-Operator

CF-Operator can be installed in a separate namespace:

```
helm install --namespace cfo --name cf-operator --set "operator.watchNamespace=scf" https://s3.amazonaws.com/cf-operators/helm-charts/cf-operator-v0.4.1%2B92.g77e53fda.tgz
```

This allows us to restart the operator, because it's not affected by webhooks. We can also delete the SCF deployment namespace to start from scratch, without redeploying the operator.

## Install SCFv3

Enable Eirini explicitly when installing. The `system_domain` DNS record needs to point to the IP of the external load balancer.

```
helm install --namespace scf --name scf https://scf-v3.s3.amazonaws.com/scf-3.0.0-82165ef3.tgz --set "system_domain=scf.suse.dev" --set "features.eirini=true"
```

## Expose SCFv3

### GKE

Make the CF router available via a load balancer:

```
kubectl expose service -n scf scf-router-v1-0 --type=LoadBalancer --name=scf-router-lb
```

The load balancers public IP should have these DNS records:

```
app1.scf.suse.dev
app2.scf.suse.dev
app3.scf.suse.dev
login.scf.suse.dev
api.scf.suse.dev
uaa.scf.suse.dev
doppler.scf.suse.dev
log-stream.scf.suse.dev
```

If you are testing locally and have no control over a DNS zone, you can enter host aliases in you r `/etc/hosts`:

```
192.168.99.112 app1.scf.suse.dev app2.scf.suse.dev app3.scf.suse.dev login.scf.suse.dev api.scf.suse.dev uaa.scf.suse.dev doppler.scf.suse.dev log-stream.scf.suse.dev
```

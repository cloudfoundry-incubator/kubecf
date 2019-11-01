# GKE Notes

Create the cluster like this:

```
project=kubecf
clustername=kubecf-test
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

After deployment of kubecf make the CF router available via a load
balancer:

```
kubectl expose service -n kubecf kubecf-router-v1-0 --type=LoadBalancer --name=kubecf-router-lb
```

The load balancer's public IP should have these DNS records:

```
app1.kubecf.suse.dev
app2.kubecf.suse.dev
app3.kubecf.suse.dev
login.kubecf.suse.dev
api.kubecf.suse.dev
uaa.kubecf.suse.dev
doppler.kubecf.suse.dev
log-stream.kubecf.suse.dev
```

If you are testing locally and have no control over a DNS zone, you
can enter host aliases in your `/etc/hosts`:

```
192.168.99.112 app1.kubecf.suse.dev app2.kubecf.suse.dev app3.kubecf.suse.dev login.kubecf.suse.dev api.kubecf.suse.dev uaa.kubecf.suse.dev doppler.kubecf.suse.dev log-stream.kubecf.suse.dev
```

# Accessing the SCF cluster

## When using NGINX Ingress Controller

NGINX Ingress Controller with Minikube enables the access from the host to the SCF cluster. Follow the
commands below for a step-by-step guide.

```sh
cf api --skip-ssl-validation "https://api.$(minikube ip).xip.io"

# Copy the admin cluster password.
kubectl get secret -n scf scf.var-cf-admin-password -o jsonpath='{.data.password}' \
  | base64 --decode \
  | less

# Use the password from the previous step when requested.
cf login -u admin
```

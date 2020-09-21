# Multi-cluster

When building a multi-cluster KubeCF, configuring a worker cluster requires settings and credentials from the control plane cluster. 
It's not a trivial task to collect all the required values manually. 
The script `generate-minions-values.sh` looks at the control plane and generates a `values.yaml` to help with configuring a worker cluster.

Usage of `generate-minions-values.sh`:

```shell
usage() {
    echo
    echo "Usage: $scriptname [OPTIONS]"
    echo
    echo "   -o"
    echo "              The output value file name for minions cluster, default is minions-values.yaml"
    echo
    echo "   -h --help  Output this help."
}
```

Run `generate-minions-values.sh` on the host with kubectl targeting to the control plane cluster.

```
$ bash generate-minions-values.sh -o test-minions-values.yaml
Generating value file for minions cluster ...
add system_domain ...
add Credentials ...
add Features ...
Complete. Please check output value file test-minions-values.yaml.
```

Part of the output file `test-minions-values.yaml` content as below:
```
system_domain: cluster01-xxxxxxxxx-0000.cloud
credentials:
  diego_bbs_client.ca: |
    -----BEGIN CERTIFICATE-----
    MIIC+jCCAeKgAwIBAgIUPKaf+972kbQ445oDear2Jsap2UgwDQYJKoZIhvcNAQEL
    BQAwFTETMBEGA1UEAxMKaW50ZXJuYWxDQTAeFw0yMDA2MzAxMjA3MDBaFw0yMTA2
    MzAxMjA3MDBaMBUxEzARBgNVBAMTCmludGVybmFsQ0EwggEiMA0GCSqGSIb3DQEB
    AQUAA4IBDwAwggEKAoIBAQCwThBvUfOXM/aTSNmc5Ss1hvRKqQCysdl9teXYyR+a
    ZxQpjGOo+GfBfFoZ8tHibP5MVOXC2jHrtk5zjbRbXWf5RVpbo/+HT9nYHFwnoGp/
    sJePX6HzXvsFzGoms25+PlLMKdxfxYcKDaI9OkJwld761ad2EKHG6oResvitxc0c
    G8++o/hnDXjJ5yhUxMriBe+fuB/fBfbCD+9nX7qFzdC8NifQjcrnhTYdO0ffQXvi
    LdeUaewYAzRz4gTun52QwM4rba8VL1b0zf5tZBEymGaKYwk7wR4rQPVrfzLoCvTo

...
...
...
```

The values file `test-minions-values.yaml` can be used when deploying KubeCF in the worker cluster.

For example: 
```
$ helm install kubecf -n kubecf . -f test-minions-values.yaml
```

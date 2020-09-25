# KubeCF

KubeCF is a Cloud Foundry distribution for Kubernetes. KubeCF installs BOSH releases from
cf-deployment as Kubernetes objects. It includes all components required for a full Cloud Foundry
Application Runtime (CFAR) PaaS on Kubernetes.


## Install the Quarks operator

This chart depends on the [Quarks operator][1], which must be installed before KubeCF to provide
Kubernetes CRDs necessary for running some components.

Each KubeCF release is paired with a specific Quarks release. Check the [KubeCF Release Notes][2] to
see which version you need. 


## Requirements 

KubeCF can be deployed to Kubernetes 1.14 or later with a persistent storage class.  


## Configuration

The complete list of settings can be seen in `values.yaml` file of this chart, but *do not* copy
this file verbatim as a starting point for your custom configuration. Some of the values are set to
provide defaults to sub-charts and are subject to change in future releases, which may break
upgrades if you reuse them in your own `values.yaml`.


| Parameter                        | Description                                                                                       | Default           |
| -------------------------------- | ------------------------------------------------------------------------------------------------- | ----------------- |
| `system_domain`                  | The domain name for your endpoint (e.g.`example.com` will expose `api.example.com` and others)    | None              |
| `kube.storage_class`             | Name of the storage class to use (if not the default storage class)                               | Default           |
| `high_availability`              | Automatically set multiple pods per role, overrides `sizing` when less than minimum HA config     | `false`           |
| `sizing.<role>.instances         | Explicitly set the number of pods for a particular role                                           | `~`               |
| `properties`                     | [BOSH properties][3]                                                                              | `{}`              |
| `credentials`                    | [BOSH explicit variables][4] (e.g. `credentials.cf_admin_password`)                               | `{}`              |
| `variables`                      | [BOSH implicit variables][5]                                                                      | `{}`              |


## Installation

See the [Deploy on Kubernetes][6] section of the [KubeCF Documentation][7] for full deployment
instructions.


[1]: https://github.com/cloudfoundry-incubator/quarks-operator
[2]: https://github.com/cloudfoundry-incubator/kubecf/releases
[3]: https://github.com/cloudfoundry-incubator/kubecf/blob/master/doc/Contribute.md#customization
[4]: https://quarks.suse.dev/docs/quarks-operator/concepts/variables/#explicit-variables
[5]: https://quarks.suse.dev/docs/quarks-operator/concepts/variables/#implicit-variables
[6]: https://kubecf.suse.dev/docs/getting-started/kubernetes-deploy/
[7]: https://kubecf.suse.dev/docs/

# SUSE Cloud Foundry (SCF)

_This is a work in progress._

## Developing

Refer to [dev/README.md](dev/README.md).

## Deploying SCF

1. Install [cf-operator][cf-operator].

2. Install SCF

  ```txt
  helm upgrade scf deploy/helm/scf/ \
    --install \
    --namespace scf \
    --set "system_domain=<the_system_domain>"
  ```

[cf-operator]: https://github.com/cloudfoundry-incubator/cf-operator

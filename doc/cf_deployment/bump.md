# Bump

The scripts in directory __dev/cf_deployment/bump__ are used when bumping
the version of the `cf-deployment` manifest.

## Requirements

  - [yq][yq]

## Scripts

  - __set_release_urls.sh__:

    To be run after updating the cf-deployment version to use and
    regenerating `assets/cf-deployment.yml`, this script regenerates
    the `assets/operations/set_release_urls.yaml` ops file which
    replaces BOSH release locations with references to the equivalent
    docker images.

[yq]: https://yq.readthedocs.io/en/latest/

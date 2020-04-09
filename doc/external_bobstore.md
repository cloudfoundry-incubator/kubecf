# Overview

CloudFoundry Application Runtime(CFAR) uses a [blobstore](https://docs.cloudfoundry.org/concepts/cc-blobstore.html) to store the source code that developers push, stage, and run. This document explains how to configure an external blobstore for the Cloud Controller.

# Background

kubecf relies on [ops files](https://github.com/cloudfoundry/cf-deployment/blob/master/operations/README.md) provided by [cf-deployment](https://github.com/cloudfoundry/cf-deployment) releases for external blobstore configurations. The default configuration for the blobstore is `singleton`.

# Configuring AWS S3

Currently AWS S3 is supported to be configured as an external blobstore. In order to configure aws s3 blobstore following configuration must be provided in your [values.yaml]().

```
blobstore:
    provider: s3
    s3:
      aws_region: "us-east-1"
      blobstore_access_key_id:  <aws-access-key-id>
      blobstore_secret_access_key: <aws-secret-access-key>
      blobstore_admin_users_password: <password-value>
      # The following values are used as S3 bucket names
      app_package_directory_key: "kubecf-apps-cf"
      buildpack_directory_key: "kubecf-buildpacks-cf"
      droplet_directory_key: "kubecf-droplets-cf"
      resource_directory_key: "kubecf-resources-cf"
```

Make sure the supplied AWS credentials have appropriate [permissions](https://docs.cloudfoundry.org/deploying/common/cc-blobstore-config.html#fog-aws-iam). 

Note: Currently there is an open issue for using any AWS region other than `us-east-1`.

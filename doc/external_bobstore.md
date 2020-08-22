# Using external blobstore with kubecf

## Overview

CloudFoundry Application Runtime(CFAR) uses a [blobstore](https://docs.cloudfoundry.org/concepts/cc-blobstore.html) to store the source code that developers push, stage, and run. This document explains how to configure an external blobstore for the Cloud Controller.

## Background

kubecf relies on [ops files](https://github.com/cloudfoundry/cf-deployment/blob/master/operations/README.md) provided by [cf-deployment](https://github.com/cloudfoundry/cf-deployment) releases for external blobstore configurations. The default configuration for the blobstore is `singleton`.

## Configuring AWS S3 blobstore

Currently AWS S3 is supported to be configured as an external blobstore. In order to configure aws s3 blobstore following configuration must be provided in your [values.yaml](https://github.com/cloudfoundry-incubator/kubecf/blob/master/chart/values.yaml#L260-L272).

```
features:
  blobstore:
      provider: s3
      s3:
        aws_region: "us-east-1"
        blobstore_access_key_id:  <aws-access-key-id>
        blobstore_secret_access_key: <aws-secret-access-key>
        # User provided value for the blobstore admin password.
        blobstore_admin_users_password: <password-rdvalue>
        # The following values are used as S3 bucket names. The buckets are automatically created if not present.
        app_package_directory_key: <apps-bucket-name>
        buildpack_directory_key: <buildpack-bucket-name>
        droplet_directory_key: <droplet-bucket-name>
        resource_directory_key: <resource-bucket-name>
```

Make sure the supplied AWS credentials have appropriate [permissions](https://docs.cloudfoundry.org/deploying/common/cc-blobstore-config.html#fog-aws-iam). 

Note: Currently there is an open [issue](https://github.com/cloudfoundry-incubator/kubecf/issues/656) for using any AWS region other than `us-east-1`.

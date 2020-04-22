# suse-buildpacks-ci

## Description

This pipeline is responsible for building images for suse buildpack releases and opening a PR against `kubecf` repo.

## Steps to deploy/modify pipeline

1. Refer the `config.yaml.prod` configuration to create a file named `config.yaml` and replace all required values.

2. Make sure the concourse target is set and you are logged in.

3. Deploy or update the pipeline using the following command:

```
./deploy-pipeline <concourse-target> <pipeline-name>
```

**Note:** Make sure you don't use the existing prod configuration for the test pipelines.

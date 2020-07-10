# Quick Guideline for Major & Minor Release

## Git Branch

Sync remote origin:
```
> git fetch origin --prune
```

Move to the origin/master branch:
```
> git checkout origin/master
```

Create a release branch following the semver rules:
```
> git checkout -b release-2.0
```

```
> git push --set-upstream origin release-2.0
```


Check [here](https://github.com/cloudfoundry-incubator/kubecf/branches) if the release-2.0 branch is protected by verifying if the release branch as the lock icon:

![](https://i.imgur.com/n8DHyeF.png)


## Files to Change

Add the version to the KubeCF helm chart target in _deploy/helm/kubecf/BUILD.bazel_:
> ```version = "v2.0.0"```

As an example:
```
helm_package(
    name = "kubecf",
    srcs = [
        ":chart_files_static",
    ],
    generated = [
        ":metadata",
    ],
    tars = [
        "//bosh/releases:pre_render_scripts",
        ":cf_deployment",
        ":extracted_jobs",
    ],
    version = "v2.0.0",
)
```


## Concourse

If the pipeline is not there already, define, commit, push, and deploy a new
Concourse pipeline for the new release branch.

Copy the kubecf.yaml config into a new config for the new release branch:

    > cp ./concourse/kubecf.yaml ./concourse/kubecf-release-X.Y.yaml

Edit `.concourse/kubecf-release-X.Y.yaml` so it targets the correct branch (See
other pipeline configs in other release branches):

```
branches:
- release-X.Y
pr_base_branch: release-X.Y
```

Commit the config into the release branch:
```
> git add .concourse/kubecf-release-X.Y.yaml; git commit -m "Add release-X.Y config"; git push
```

Login to the Concourse server:

```
> fly --target concourse.suse.dev login --team-name main --concourse-url https://concourse.suse.dev
```

Deploy the pipeline:
```
> cd "$(git rev-parse --show-toplevel)/.concourse"; ./create-pipeline.sh concourse.suse.dev kubecf-release-X.Y
```

Download the bundle directly from the _build_ job and perform a sanity check on the chart:

```
> helm inspect chart https://s3.eu-central-1.amazonaws.com/kubecf-ci/kubecf-v2.0.0.tgz
```

## Github

Create a new release using the same template from the previous one and upload both the bundle and the KubeCF tar files (download from the Concourse *build* job).


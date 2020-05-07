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
> git checkout -b v2.0.0
```

```
> git push --set-upstream origin v2.0.0
```


Check [here](https://github.com/cloudfoundry-incubator/kubecf/branches) if the v2.0.0 branch is protected by verifying if the release branch as the lock icon:

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

Update the Concourse pipeline _.concourse/pipeline.yaml.gomplate_ by adding the new release branch to the list of branches:
```{{ $branches := slice "master" "v2.0.0" }} # Repository branches to track```

## Concourse

Login to the Concourse server:

```
> fly --target concourse.suse.dev login --team-name main --concourse-url https://concourse.suse.dev
```

Deploy the pipeline:
```
> (cd "$(git rev-parse --show-toplevel)/.concourse"; ./fly --target concourse.suse.dev set-pipeline --pipeline kubecf)
```

Download the bundle directly from the _build_ job and perform a sanity check on the chart:
```
> helm inspect chart https://s3.eu-central-1.amazonaws.com/kubecf-ci/kubecf-v2.0.0.tgz
```

## Github

Create a new release using the same template from the previous one and upload both the bundle and the KubeCF tar files (download from the Concourse *build* job).


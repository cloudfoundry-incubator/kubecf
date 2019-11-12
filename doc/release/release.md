# Release Process

## Considerations

## Prerequisites

1. set version number (e.g. version=v1.2.0) 
2. select a master commit (e.g. commit=187dda2bea628d90354c0dd458bfb79f11c434c1) and browse the files (e.g. https://github.com/SUSE/kubecf/tree/187dda2bea628d90354c0dd458bfb79f11c434c1) from that commit specificaly, to avoid collecting information commited after (can happen)
2. copy the KubeCF helm chart [link](https://scf-v3.s3.amazonaws.com/index.html) associated with the commit hash selected on step 1 (e.g. kubecf-chart=https://scf-v3.s3.amazonaws.com/kubecf-3.0.0-187dda2.tgz)
3. copy the CF-Operator helm chart URL from the [bazel file definition](./def.bzl) file, located at the root level of the project (e.g. cf-operator-chart=https://cf-operators.s3.amazonaws.com/helm-charts/cf-operator-v0.4.2%2B128.g79ec4885.tgz)
4. set the CF-Opertor version by parsing the link from step 3 (e.g. cf-operator-version=0.4.2+128.g79ec4885)
example:
```
cf_operator = struct(
        chart = struct(
            url = "https://cf-operators.s3.amazonaws.com/helm-charts/cf-operator-v0.4.2%2B128.g79ec4885.tgz",
            sha256 = "06c07a198fab6cd0db60b8543bfb3c9a53e026a102bf34847fda1a28f27dd9c0",
        ),
        namespace = "cfo",
    ),
```

## Release Template

Now is time to fill the [template](release-template.md) placeholders with relevant information collected before along with new cool stuff coming on this feature (manual step for now).

## Verification(s)

1. Check if the Gitlab pipeline related with the specific commit is green for all the stages (e.g. https://gitlab.com/susecf/kubecf/commit/187dda2bea628d90354c0dd458bfb79f11c434c1)

## Github Release

After having the release template ready and double check the CI pipeline on Gitlab, it's time to create a new release on Github and for that just go to the Github project release [page](https://github.com/SUSE/kubecf/releases) and do your magic.

v0.0.0-alpha draft can be used as guideline and don't forget to open PR against this document if you have better ideas and/or if you find any incorrections.
# Steps for bumping cf-deployment version:

## Bump release versions:

- Update the target cf-deployement version in: https://github.com/SUSE/kubecf/blob/master/def.bzl

- Update the buildpack file paths in https://github.com/SUSE/kubecf/blob/master/deploy/helm/kubecf/assets/operations/instance_groups/api.yaml to reflect corresponding versions in cf-deployment.


## Inspecting changes:

- Compare the existing cf-deployment version against the target version to identify changes:\
  `https://github.com/cloudfoundry/cf-deployment/compare/<existing_version>...<target_version>`

- If there are no changes in releases(except from version bumps), instance groups and jobs then skip to next section.

- If a release is added, removed or modified then make sure that the [pre_render_scripts](https://github.com/SUSE/kubecf/tree/master/bosh/releases/pre_render_scripts) are updated accordingly.

- If an instance group is added, removed or modified then make sure that the [instance_groups](https://github.com/SUSE/kubecf/tree/master/deploy/helm/kubecf/assets/operations/instance_groups) ops file is updated accordingly.

_Note that the above steps will vary depending upong the changes in target version._

## Build Release Images:

- Make sure the release images for the target cf-deployment version are available. If not then add the target cf-deployment version in [cf-deployment build-pipelines](https://github.com/SUSE/cf-ci/tree/develop/kubecf-build-pipelines/cf-deployment) and update then trigger the build job in concourse.

## Bump CATs release:

- Update [cf-acceptance-tests-release](https://github.com/SUSE/cf-acceptance-tests-release) to reflect target cf-deployment version. This can be done by updating the submodule in src/... directory.
- Trigger the final-releases build pipeline to create a new CATs release.
- Use this release to build a new release image by adding the new version of cf-acceptance-tests-release in: https://github.com/SUSE/cf-ci/tree/develop/kubecf-build-pipelines/external-releases
- Bump the latest version of cf-acceptance-tests-release in: https://github.com/SUSE/kubecf/blob/master/deploy/helm/kubecf/values.yaml

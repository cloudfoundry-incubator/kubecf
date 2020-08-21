# Steps for bumping cf-deployment version

## Bump release versions

- Update the target `cf-deployement` version and sha256 in
  https://github.com/SUSE/kubecf/blob/master/dependencies.yaml.

- Update the `buildpack` version numbers / file paths in
  https://github.com/SUSE/kubecf/blob/master/chart/values.yaml
  to reflect corresponding versions in `cf-deployment`.

## Inspecting changes

- Compare the existing cf-deployment version against the target version to identify changes:
  `https://github.com/cloudfoundry/cf-deployment/compare/<existing_version>...<target_version>`

- If there are no changes in releases (except version bumps), instance groups and jobs then skip to
  the next section.

- If a release is added, removed or modified, then make sure that the
  [pre_render_scripts](https://github.com/SUSE/kubecf/tree/master/bosh/releases/pre_render_scripts)
  are updated accordingly.

- If an instance group is added, removed or modified, then make sure that the
  [instance_groups](https://github.com/SUSE/kubecf/tree/master/chart/assets/operations/instance_groups)
  ops-file is updated accordingly.

_Note that the above steps will vary depending upon the changes in the target version._

## Build Release Images

- Make sure the release images for the target cf-deployment version are available. If not, add the
  target cf-deployment version in
  [cf-deployment build-pipelines](https://github.com/SUSE/cf-ci/tree/develop/kubecf-build-pipelines/cf-deployment)
  and update. Then, trigger the build job in Concourse.

## Bump CATs release

- Update [cf-acceptance-tests-release](https://github.com/SUSE/cf-acceptance-tests-release) to
  reflect the target cf-deployment version. This can be done by updating the submodule in src/...
  directory.
- Trigger the final-releases build pipeline to create a new CATs release.
- Use this BOSH release to build a new release image by adding the new version of
  cf-acceptance-tests-release in
  https://github.com/SUSE/cf-ci/tree/develop/kubecf-build-pipelines/external-releases.
- Bump the latest version of cf-acceptance-tests-release in
  https://github.com/SUSE/kubecf/blob/master/chart/values.yaml.

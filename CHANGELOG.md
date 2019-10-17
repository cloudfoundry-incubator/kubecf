# Changelog

## [2.16.4] - 2019-05-07

## Fixed
- Reverted cf-mysql-release to 36.15.0 to avoid intermittent database connectivity errors in HA setup

## [2.16.3] - 2019-05-02

## Fixed
- Reverted the incompatible changes in statefulsets
- Changed app autoscaler-postgres to a non-HA setup

## [2.16.2] - 2019-04-30

## Changed
- Bumped binary-buildpack to 1.0.32
- Bumped CAPI to 1.79.0
- Bumped dotnet-core-buildpack to 2.2.10
- Bumped Eirini release to 0.0.4
- Bumped nginx-buildpack to 1.0.11
- Bumped nodejs-buildpack to 1.6.49
- Bumped php-buildpack to 4.3.75
- Bumped python-buildpack to 1.6.32
- Bumped ruby-buildpack to 1.7.38
- Bumped SLE12 stack
- Bumped SLE15 stack
- Bumped staticfile-buildpack to 1.4.42


## Fixed
- Cleaned up role readiness probe outputs
- Fix nfs-persi brain failures when running on NFS


## [2.16.1] - 2019-04-16

## Added
- Added support for user supplied annotations for Ingress

## Changed
- Added Helm labels to Ingress templates
- Bumped SLE15 stack
- Bumped nodejs buildpack to 1.6.48
- Bumped Eirini to 0.0.3
- Bumped cflinuxfs2 to 1.281.0
- Bumped cflinuxfs3 to 0.81.0
- Bumped Ruby buildpack to 1.7.36
- Bumped PHP buildpack to 4.3.74
- Bumped Python buildpack to 1.6.31
- Bumped Java buildpack to 4.19.1

## Fixed
- Fixed the diego-api readiness probe 
- Fixed autoscaler to not skip SSL validation
- Reduced autoscaler database disk size
- Fixed autoscaler to listen to cluster internal CF API endpoint 

## [2.16.0] - 2019-02-04

## Added
- Added Eirini Tech Preview
- Added SLE15 stack 
- Added feature flags to enable roles such as autoscaler, credhub, cf-usb, eirini
- Added SITS (Sync Integration Test Suite)
- Added support for Ingress Controller
- Added .net-core-buildpack (2.2.7)

## Changed
- Bumped to cf-deployment 6.10
- Bumped cflinuxfs3 to 0.76.0
- Bumped cflinuxfs2 to 1.278.0
- Bumped binary-buildpack-release to 1.0.31
- Bumped cf-cli to 6.42.0
- Bumped go-buildpack to 1.8.36
- Bumped java-buildpack to 4.19.0
- Bumped nfs-volume-release to 1.7.6
- Bumped nginx-buildpack to 1.0.10
- Bumped nodejs-buildpack to 1.6.47
- Bumped php-buildpack to 4.3.70
- Bumped python-buildpack to 1.6.30
- Bumped ruby-buildpack to 1.7.35
- Bumped staticfile-buildpack to 1.4.41
- Bumped up the nproc limits for vcap user
- Doppler is communicating on port 443
- Enabled mutual TLS between cloud controller and GoRouter
- Changed cloud controller ports to be non-configurable
- Converted the cc-clock's wait-for-api functionality from a patch to a pre-start script

## Fixed
- Fixed the test for an insecure docker registry (uses tcpdomain for the route)

## [2.15.2] - 2019-02-08

## Added
- cflinuxfs3 now available
- Support added for placement zones & isolation segments

## Changed
- Bumped cflinuxfs2 to 1.266.0
- Bumped binary-buildpack to 1.0.30.1
- Bumped go-buildpack to 1.8.33.1
- Bumped java-buildpack to 4.17.2.1
- Bumped nginx-buildpack to 1.0.8.1
- Bumped nodejs-buildpack to 1.6.43.1
- Bumped php-buildpack to 4.3.70.1
- Bumped python-buildpack to 1.6.27.1
- Bumped ruby-buildpack to 1.7.31.1
- Bumped staticfile-buildpack to 1.4.39.1
- Bumped SLE12 & openSUSE stacks

## Fixed
- Certificates rely on correct UAA FQDN
- Removed obsolete key from role-manifest.yml
- Removed diego-cell readiness probe from role-manifest.yml

## [2.15.1] - 2019-01-22

## Added
- Enabled Ingress Controller
- Added nginx buildpack
- Set up default PSPs 
- Specify SYS_RESOURCE capabilities for roles that need it

## Changed
- Bumped SLE12 & openSUSE stacks
- Bumped nodejs buildpack to 1.6.41.1
- Bumped Go buildpack to 1.8.31.1
- Bumped Ruby buildpack to 1.7.30.1
- Bumped staticfile buildpack to 1.4.38.1
- v3 API now uses HTTPS instead of HTTP
- Bumped java-buildpack to 4.17.1.1
- Restored DEFAULT_STACK to cflinuxfs2
- Bumped php-buildpack to 4.3.68.2
- Bumped binary-buildpack to 1.0.29.1

## Fixed
- klog.sh now supports multi-container pods
- Fixed stemcell to include latest pre start scripts

## [2.15.0] - 2018-12-20

## Added
- New variable appVersion available in Helm

## Changed
- Bumped cf-deployment to 3.6.0
- Bumped staticfile buildpack to 1.4.36.1
- Bumped nodejs buildpack to 1.6.37.1
- Bumped php buildpack to 4.3.66.1
- Bumped binary buildpack to 1.0.28.1
- Bumped Java buildpack to 4.16.1.1
- Bumped python buildpack to 1.6.24.1
- Bumped Ruby buildpack to 1.7.27.1
- Bumped SLE12 & openSUSE stacks
- App-autoscaler no longer dependent on hairpin
- Using upstream credhub instead of our own fork
- Metron replaces loggregator as a new sidecar for those pods where loggregator ran as a service internally before

## Fixed  
- External URL for USB fixed whereby job name doesn't appear in service name anymore

## [2.14.5] - 2018-11-07

## Changed
- Bumped SLE12 stack
- Bumped java buildpack to 4.16.1
- Bumped binary buildpack to 1.0.27.1
- Bumped nodejs buildpack to 1.6.34.1

## Fixed
- Corrected service name to work with syslog drains

## [2.14.4] - 2018-11-05

## Changed
- Bumped SLE12 stack
- Bumped configgin to 0.18.3

## Fixed
- IP mappings are refreshed when pods are restarted in HA
 
## [2.14.3] - 2018-11-02

### Added
- UAA charts now have affinity/antiaffinity logic

### Changed
- Bumped ruby buildpack to 1.7.26.1
- Bumped SLE12 stack
- Bumped fissile to 0.0.1-321-g6c32268

### Fixed
- Renaming of api DNS internally to address apps not coming up in a timely fashion post-upgrade

## [2.14.2] - 2018-10-30

### Changed
- Use app.kubernetes.io/component instead of skiff-role-name label
- Bumped app-autoscaler to 1.0.0
- Bumped SLE12 & openSUSE stacks
- Bumped go buildpack to 1.8.28.1
- Bumped php buildpack to 4.3.62.1
- Bumped python buildpack to 1.6.23.1
- Bumped ruby buildpack to 1.7.25.1
- Bumped fissile to 0.0.1-318-g00f1932

### Fixed
- diego.file_server_url preserved from previous releases to maintain communication after upgrade
- Fixed stateful set clustering references for HA deployments

## [2.14.1] - 2018-10-03

### Changed
- Removed no longer needed consul & postgres roles
- Bumped SLE12 & openSUSE stacks

### Fixed
- Updated cluster role names to ensure no namespace conflicts in Kubernetes

## [2.14.0] - 2018-09-27

### Added
- Credhub introduced as a user-accessible component (independent of future cf-deployment requirements)
- Exposed SMTP_HOST & SMTP_FROM_ADDRESS variables to allow for account creation & password reset

### Changed
- One Kubernetes service per job now, whereby the service names will include both the instance group (previously the role) and job name, which impacts the role manifest YAML 
- Bumped python & Ruby buildpacks
- Bumped SLE12 & openSUSE stacks

### Fixed
- Kubernetes readiness check no longer looks for hyperkube explicitly

## [2.13.3] - 2018-09-11

### Fixed
- Error in configgin update

## [2.13.2] - 2018-09-10

### Changed
- Bumped configgin

### Fixed
- configgin can now find lower-numbered role pods to help with upgrades

## [2.13.1] - 2018-09-04

### Changed
- Bumped go & Ruby buildpacks
- Bumped SLE12 & openSUSE stacks

### Fixed
- fissile now uses port numbers for exposed services, addressing a Kubernetes behaviour spotted during upgrades
- Provide warnings when HA UAA relies on SSO lifecycle tests

## [2.13.0] - 2018-08-27

### Added
- broker_client_timeout_seconds variable exposed

### Changed
- Bumped app-autoscaler-release to 8d6cb15
- Bumped openSUSE stack

### Fixed
- Reverted changes to database role rename based on issue with volumes during upgrade
- CF version number in filename properly updated

## [2.12.3] - 2018-08-22

### Added
- Allow HA for cc-clock and syslog-scheduler roles (2 default/3 max)

### Changed
- Changed internal ports to avoid privileged ports in Kubernetes, though diego-cell and nfs-broker containers still rely on privileged access
- Bumped cf-deployment to 2.7.0
- Bumped capi-release to 1.61.0
- Bumped cf-syslog-drain-release to 7.0
- Bumped cflinuxfs2-release to 1.227.0
- Bumped consule-release to 195
- Bumped diego-release to 2.12.1
- Bumped routing-release to 0.179.0
- Bumped uaa-release to 60.2
- Bumped loggregator to 103
- Bumped SLE12 & openSUSE stacks

### Fixed
- syslog-adapter added to syslog adapter cert

## [2.12.2] - 2018-08-16

## Changed
- Bumped SLE12 & openSUSE stacks

## [2.12.1] - 2018-08-15

### Changed
- Bumped SLE12 & openSUSE stacks

## [2.12.0] - 2018-08-14

### Added
- App-autoscaler included (off by default)
- Groot-btrfs now available
- Enabled cloud controller security events
- nfs-broker can now be HA

### Changed
- Realigned cf role composition more inline with upstream
- mysql-proxy role has been merged into the mysql role
- diego-locket role merged into diego-api
- log-api role combines loggregator and syslog-rlp roles
- Renamed syslog-adapter role to adapter
- Removed processes list from all roles
- Removed duplicate routing_api.locket.api_location property
- Bumped garden-runc-release to 1.15.1 to rely on go-nats
- Bumped ruby-buildpack to 1.7.21.1
- Bumped SLE12 & openSUSE stacks
- Bumped kubectl to 1.9.6
- Bumped cf-cli to 6.37.0

### Fixed
- INTERNAL_CA_KEY not included in every pod by default
- Better mechanism for waiting on MySQL

## [2.11.0] - 2018-06-26

### Added
- Certificate expiration now configurable
- Added support for manual rotation of cloud controller database keys
- New active/passive role management for pods
- Exposed router.client_cert_validation property

### Changed
- Bumped cf-deployment to 1.36
- Bumped UAA to v59
- Bumped diego-release to 2.8.0
- Bumped SLE12 & openSUSE stacks
- Bumped ruby-buildpack to 1.7.18.2
- Bumped go-buildpack to 1.8.22.1
- Bumped kubectl to 1.8.2
- Use namespace for helm install name

### Fixed
- Load balancer for Azure now usable
- Updated role manifest validation to let secrets generator use KUBE_SERVICE_DOMAIN_SUFFIX without configuring HA itself
- SCF_LOG_PORT now set to default of 514
- Fixed issue during upgrade whereby USB did not receive updated password info
- Patched monit_rsyslogd timestamp

## [2.10.1] - 2018-05-17 

### Changed
- Disabled optional consul role

### Fixed
- Immutable config variables will not be regenerated

## [2.10.0] - 2018-05-16

### Added
- cfdot added to all diego roles

### Changed
- Bumped SLE12 & openSUSE stacks
- Rotateable secrets are now immutable

### Fixed
- Upgrades for legacy versions that were using an older secrets generation model
- Upgrades will handle certificates better by having the required SAN metadata
- Apps will come back up and run after upgrade

## [2.9.0] - 2018-05-07

### Added
- The previous CF/UAA bumps should be considered minor updates, not patch releases, so we will bump this verison in light of the changes in 2.8.1 and rely on this as part of future semver

### Changed
- Bump PHP buildpack to v4.3.53.1 to address MS-ISAC ADVISORY NUMBER 2018-046

### Fixed
- Fixed string interpolation issue

## [2.8.1] - 2018-05-04

### Added
- Enabled router.forwarded_client_cert variable for router
- New syslog roles can have anti-affinity
- mysql-proxy healthcheck timeouts are configurable 

### Changed
- Bumped UAA to v56.0
- Bumped cf-deployment to v1.21
- Bumped SLE12 & openSUSE stacks
- Removed time stamp check for rsyslog

### Fixed
- MySQL HA scaling up works better

## [2.8.0] - 2018-04-03

### Added
- Added mysql-proxy for UAA
- Exposed more log variables for UAA

### Changed
- Bumped SLE12 stack
- Bumped fissile to 5.2.0+6
- Variable kube.external_ip now changed to kube.external_ips

### Fixed
- Addressed issue with how pods were indexed with invalid formatting 

## [2.7.3] - 2018-03-23
### Added
- TCP routing ports are now configurable and can be templatized
- CPU limits can now be set
- Kubernetes annotations enabled so operators can specify which nodes particular roles can run on

### Changed
- Bumped fissile to 5.1.0+128

### Fixed
- Changed how secrets are generated for rotation after 2.7.1 and 2.7.2 ran into problems during upgrades

## [2.7.2] - 2018-03-07
### Changed
- Bumped fissile to 5.1.0+89

## [2.7.1] - 2018-03-06
### Added
- Allow more than one IP address for external IPs
- MySQL now a clustered role
- More configurations for UAA logging level

### Changed
- To address CVE-2018-1221, bumped CF Deployment to 1.15 and routing-release to 0.172.0
- Bumped UAA to v55.0
- Bumped SLE12 & openSUSE stacks
- Bumped buildpack versions to latest

### Fixed
- Make the cloud controller clock role wait until the API is ready

## [2.7.0] - 2018-02-09
### Added
- Add ability to rename immutable secrets

### Changed
- Bump to CF Deployment (1.9.0), using CF Deployment not CF Release from now on
- Bump UAA to v53.3
- Update CATS to be closer to what upstream is using
- Make RBAC the default in the values.yaml (no need to specify anymore)
- Increase test brain timeouts to stop randomly failing tests
- Remove unused SANs from the generated TLS certificates
- Remove the dependency on jq from stemcells

### Fixed
- Fix duplicate buildpack ids when starting Cloud Foundry
- Fix an issue in the vagrant box where compilation would fail due
  to old versions of docker.
- Fix an issue where diego cell could not mount nfs in persi
- Fix many problems reported with the syslog forwarding implementation

## [2.6.11] - 2018-01-17
### Changed
- Helm charts now are published by ci with the correct registry.

## [2.6.10-rc3] - 2018-01-05
### Changed
- Combine variables controlling openSUSE vs SLES builds.

## [2.6.9-rc2] - 2018-01-05
### Changed
- Helm versions no longer include the build information in the semver
- Which stemcell is used is no longer governed by CI but by make files
- Jenkins now prevents overwriting of artifacts
- Prevent use of unconfigured stacks

### Fixed
- Fix mutual TLS when HA mode is true (fixes HA deployment problems)
- Fix ruby app deployment problem (missing libmysqlclient in stack)
- Fix configgin having insufficient permissions to configure HA deploy
- Fix issue where buildpacks couldn't upload because blobstore size limits

#!/usr/bin/env bash

set -o errexit

# Patch config/bpm.yml.erb to set the correct tomcat path.
patch /var/vcap/all-releases/jobs-src/uaa/uaa/templates/config/bpm.yml.erb <<'EOT'
5,6c5,6
<     CATALINA_BASE: /var/vcap/data/uaa/tomcat
<     CATALINA_HOME: /var/vcap/data/uaa/tomcat
---
>     CATALINA_BASE: /var/vcap/packages/uaa/tomcat
>     CATALINA_HOME: /var/vcap/packages/uaa/tomcat
EOT

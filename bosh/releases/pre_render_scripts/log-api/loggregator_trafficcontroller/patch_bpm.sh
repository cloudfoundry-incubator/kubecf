#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/loggregator/loggregator_trafficcontroller/templates/bpm.yml.erb"

patch --binary --unified --verbose "${target}" <<'EOT'
@@ -35,7 +35,7 @@
       CC_CA_FILE: "/var/vcap/jobs/loggregator_trafficcontroller/config/certs/mutual_tls_ca.crt"
       CC_SERVER_NAME: "<%= p('cc.internal_service_hostname') %>"

-      TRAFFIC_CONTROLLER_IP: "<%= spec.ip %>"
+      TRAFFIC_CONTROLLER_IP: "scf-log-api"
       TRAFFIC_CONTROLLER_API_HOST: "<%= "https://#{p('cc.internal_service_hostname')}:#{p('cc.tls_port')}" %>"
       TRAFFIC_CONTROLLER_OUTGOING_DROPSONDE_PORT: "<%= p("loggregator.outgoing_dropsonde_port") %>"
       TRAFFIC_CONTROLLER_OUTGOING_CERT_FILE: "/var/vcap/jobs/loggregator_trafficcontroller/config/certs/trafficcontroller_outgoing.crt"

EOT

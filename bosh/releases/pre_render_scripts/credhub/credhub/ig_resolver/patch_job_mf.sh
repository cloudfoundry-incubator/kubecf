#!/usr/bin/env bash

set -o errexit -o nounset

release="credhub"
job="credhub"
job_mf="/var/vcap/all-releases/jobs-src/${release}/${job}/job.MF"
patch --verbose "${job_mf}" <<'EOT'
@@ -76,11 +76,6 @@ provides:
   - credhub.data_storage.type
   - credhub.data_storage.username

-consumes:
-- name: postgres
-  type: database
-  optional: true
-
 properties:
   credhub.port:
     description: "Listening port for the CredHub API"
EOT

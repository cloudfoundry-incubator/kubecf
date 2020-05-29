#!/usr/bin/env bash

function patch() {
    local target="${1}"
    local sentinel="${1}.patch_sentinel"
    if [[ -r "${sentinel}" ]]; then
        if sha256sum --check "${sentinel}" ; then
            echo "Patch already applied. Skipping ${target}"
            return 0
        fi
        echo "Sentinel mismatch, re-patching ${target}"
    fi
    command patch --verbose --batch --strip=1 "${target}" # << STDIN
}

patch "/var/vcap/all-releases/jobs-src/mapfs/mapfs/job.MF" <<"EOP"
diff --git a/jobs/mapfs/spec b/jobs/mapfs/spec
index 65cbf0f..1f25355 100644
--- a/jobs/mapfs/spec
+++ b/jobs/mapfs/spec
@@ -3,6 +3,7 @@ name: mapfs
 
 templates:
   install.erb: bin/pre-start
+  bpm.yml.erb: config/bpm.yml
 
 packages:
 - mapfs
EOP

cat > "/var/vcap/all-releases/jobs-src/mapfs/mapfs/templates/bpm.yml.erb" <<"EOF"
processes:
  - name: mapfs
    executable: /bin/sh
    args:
    - -c
    - >
      echo "Sleeping forever; mapfs only runs as pre-start" ;
      while true ; do
      sleep 365d ;
      done
hooks:
  pre_start: /var/vcap/jobs/mapfs/bin/pre-start
EOF

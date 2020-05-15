#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/diego/rep/templates/bpm.yml.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

# Patch BPM, since we're actually running in-cluster without BPM
patch --verbose "${target}" <<'EOT'
@@ -6,7 +6,7 @@
     open_files: 100000
   hooks:
     pre_start: /var/vcap/jobs/rep/bin/bpm-pre-start
-  ephemeral_disk: true
+  ephemeral_disk: false
   additional_volumes:
     - path: <%= p("diego.executor.volman.driver_paths") %>
     - path : /var/vcap/data/garden
EOT

sha256sum "${target}" > "${sentinel}"

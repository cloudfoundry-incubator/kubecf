#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/garden-runc/garden/templates/config/bpm.yml.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

# add -s option to enable the subreaper because we are not running tini as pid 1
# add -w option to produce a warning every time tini reaps a zombie process
patch --verbose "${target}" <<'EOT'
@@ -2,6 +2,8 @@ processes:
   - name: garden
     executable: /var/vcap/packages/tini/bin/tini
     args:
+      - -s
+      - -w
       - --
       - /var/vcap/jobs/garden/bin/garden_start
     unsafe:
EOT

sha256sum "${target}" > "${sentinel}"

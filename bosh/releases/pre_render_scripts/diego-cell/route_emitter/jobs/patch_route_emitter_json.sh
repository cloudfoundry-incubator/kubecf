#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/diego/route_emitter/templates/route_emitter.json.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

# Don't share /var/vcap/packages between containers.
patch --verbose "${target}" <<'EOT'
@@ -99,7 +99,7 @@
   end

   if p("diego.route_emitter.local_mode")
-    config[:cell_id] = spec.id
+    config[:cell_id] = 'minions-1-' + spec.id
   end

   config[:enable_internal_emitter] = p("internal_routes.enabled")
EOT

sha256sum "${target}" > "${sentinel}"

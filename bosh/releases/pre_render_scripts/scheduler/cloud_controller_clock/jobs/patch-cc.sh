#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/capi/cloud_controller_clock/templates/bin/cloud_controller_clock.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

patch --verbose "${target}" <<'EOT'
@@ -2,4 +2,6 @@

 source /var/vcap/jobs/cloud_controller_clock/bin/ruby_version.sh
 cd /var/vcap/packages/cloud_controller_ng/cloud_controller_ng
+patch -p0 < /var/vcap/all-releases/jobs-src/capi/cloud_controller_ng/opi-task.patch
+
 exec bundle exec rake clock:start
EOT

sha256sum "${target}" > "${sentinel}"

cat <<'EOT' > /var/vcap/all-releases/jobs-src/capi/cloud_controller_ng/opi-task.patch
diff --git lib/cloud_controller/opi/task_client.rb lib/cloud_controller/opi/task_client.rb
index 57662b99a..b4f512149 100644
--- lib/cloud_controller/opi/task_client.rb
+++ lib/cloud_controller/opi/task_client.rb
@@ -36,18 +36,7 @@ module OPI
     end

     def fetch_tasks
-      resp = client.get('/tasks')
-
-      if resp.status_code != 200
-        raise CloudController::Errors::ApiError.new_from_details('TaskError', "response status code: #{resp.status_code}")
-      end
-
-      tasks = JSON.parse(resp.body)
-      tasks.each do |task|
-        task['task_guid'] = task.delete('guid')
-      end
-
-      tasks.map { |t| OPI.recursive_ostruct(t) }
+      []
     end

     def cancel_task(guid)
EOT

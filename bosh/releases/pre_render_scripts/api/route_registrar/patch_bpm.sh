#!/usr/bin/env bash

set -o errexit

# Patch the route_registrar to remove the unrestricted_volumes. This patch takes effect in every
# instance group that uses the route_registrar job. The unrestricted_volumes don't play well with
# other jobs in the same instance group because it wipes out /var/vcap/data/<job>.
patch --binary --unified /var/vcap/all-releases/jobs-src/routing/route_registrar/templates/bpm.yml.erb <<'EOT'
@@ -6,25 +6,3 @@
     - /var/vcap/jobs/route_registrar/config/registrar_settings.json
     - -timeFormat
     - rfc3339
-<%
-  paths = []
-  routes = p('route_registrar.routes')
-  routes.each do |route|
-    if route['health_check']
-      # valid path is /var/vcap/jobs/JOB
-      matched = /(^\/var\/vcap\/jobs\/[^\/]*)\/.*/.match(route['health_check']['script_path'])
-      if matched
-        paths << matched[1]
-      end
-    end
-  end
-
-  unless paths.empty? %>
-    unsafe:
-      unrestricted_volumes:
-<% end
-   paths.each do |path| %>
-         - path: <%= path %>
-           allow_executions: true
-         - path: <%= path.sub! 'jobs', 'data' %>
-<% end %>
EOT

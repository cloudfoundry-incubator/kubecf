#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/garden-runc/garden/templates/bin/post-start"

# Patch the post-start script to use netcat instead of curl when performing the ping to a unix
# socket. curl support for unix sockets varies considerably depending on its version.
PATCH=$(cat <<'EOT'
@@ -1,19 +1,21 @@
 #!/usr/bin/env bash
 set -euo pipefail

-# shellcheck disable=SC1091
-source /var/vcap/jobs/garden/bin/post-start-env
-curl_args=("${curl_args[@]}")  # ensure curl_args is defined
-
 start="$( date +%s )"
 timeout=120

 echo "$(date): Pinging garden server..."
 i=1

+<% if p("garden.listen_network") == "tcp" -%>
+cmd='curl -s <%= p("garden.listen_address") %>/ping'
+<% else -%>
+cmd='echo -e "GET /ping HTTP/1.1\r\n\r\n" | nc -U <%= p("garden.listen_address") %>'
+<% end -%>
+
 while [ $(( $(date +%s) - timeout )) -lt "$start" ]; do
   echo "$(date): Attempt $i..."
-  if curl -s "${curl_args[@]}"; then
+  if sh -c "${cmd}"; then
     echo "$(date): Success!"
     exit 0
   fi
EOT
)

# Only patch once
if ! patch --binary --reverse --dry-run -f "${target}" <<<"$PATCH" 2>&1  >/dev/null ; then
  patch --binary --verbose "${target}" <<<"$PATCH"
else
  echo "Patch already applied. Skipping"
fi
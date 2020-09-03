#!/usr/bin/env bash

set -o errexit -o nounset

target="/var/vcap/all-releases/jobs-src/garden-runc/garden/templates/bin/grootfs-utils.erb"
sentinel="${target}.patch_sentinel"
if [[ -f "${sentinel}" ]]; then
  if sha256sum --check "${sentinel}" ; then
    echo "Patch already applied. Skipping"
    exit 0
  fi
  echo "Sentinel mismatch, re-patching"
fi

# Patch grootfs-utils to restrict the size of the sparse stores
patch --verbose "${target}" <<'EOT'
7,8c7,17
<   /var/vcap/packages/thresholder/bin/thresholder "<%= p("grootfs.reserved_space_for_other_jobs_in_mb") %>" "$DATA_DIR" "$GARDEN_CONFIG_DIR/grootfs_config.yml" "<%= p("garden.graph_cleanup_threshold_in_mb") %>" "<%= p("grootfs.graph_cleanup_threshold_in_mb") %>"
<   /var/vcap/packages/thresholder/bin/thresholder "<%= p("grootfs.reserved_space_for_other_jobs_in_mb") %>" "$DATA_DIR" "$GARDEN_CONFIG_DIR/privileged_grootfs_config.yml" "<%= p("garden.graph_cleanup_threshold_in_mb") %>" "<%= p("grootfs.graph_cleanup_threshold_in_mb") %>"
---
>   let grootfs_size="<%= p("grootfs.reserved_space_for_other_jobs_in_mb") %>"
>   let disk_size=`df -BM /var/vcap/data/grootfs/store/ | tail -n 1 | awk '{gsub("M", "", $2); print $2}'`
>   let reserved_disk="$disk_size - $grootfs_size"
> 
>   if [ "$grootfs_size" -gt "$disk_size" ]; then
>     echo "The node running this cell doesn't have enough disk space. You requested ${grootfs_size}M but the disk is ${disk_size}M in size."
>     exit 1
>   fi
> 
>   /var/vcap/packages/thresholder/bin/thresholder "$reserved_disk" "$DATA_DIR" "$GARDEN_CONFIG_DIR/grootfs_config.yml" "<%= p("garden.graph_cleanup_threshold_in_mb") %>" "<%= p("grootfs.graph_cleanup_threshold_in_mb") %>"
>   /var/vcap/packages/thresholder/bin/thresholder "$reserved_disk" "$DATA_DIR" "$GARDEN_CONFIG_DIR/privileged_grootfs_config.yml" "<%= p("garden.graph_cleanup_threshold_in_mb") %>" "<%= p("grootfs.graph_cleanup_threshold_in_mb") %>"
EOT

sha256sum "${target}" > "${sentinel}"

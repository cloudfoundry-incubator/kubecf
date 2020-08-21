#!/bin/bash

#    Copyright The Helm Authors.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#
# This file was obtained from:
# https://github.com/helm/charts/blob/7ccc9f99d7ab6b9554624985d9c9b9723b7253c0/stable/percona-xtradb-cluster/files/entrypoint.sh

set -e

if [[ -n "${DEBUG}" ]]; then
    set -x
fi

# shellcheck disable=SC1091
. /startup-scripts/functions.sh

ipaddr=$(hostname -i | awk ' { print $1 } ')
hostname=$(hostname)
echo "I AM $hostname - $ipaddr"

# if command starts with an option, prepend mysqld
if [ "${1:0:1}" = '-' ]; then
    CMDARG=( "$@" )
fi

cluster_join=$(resolveip -s "${K8S_SERVICE_NAME}" || echo "")
if [[ -z "${cluster_join}" ]]; then
    echo "I am the Primary Node"
    init_mysql
    write_password_file
    exec mysqld --user=mysql --wsrep_cluster_name="$SHORT_CLUSTER_NAME" --wsrep_node_name="$hostname" \
    --wsrep_cluster_address=gcomm:// --wsrep_sst_method=xtrabackup-v2 \
    --wsrep_sst_auth="xtrabackup:$XTRABACKUP_PASSWORD" \
    --wsrep_node_address="$ipaddr" --pxc_strict_mode="$PXC_STRICT_MODE" "${CMDARG[@]}"
else
    echo "I am not the Primary Node"
    chown -R mysql:mysql /var/lib/mysql || true # default is root:root 777
    touch /var/log/mysqld.log
    chown mysql:mysql /var/log/mysqld.log
    write_password_file
    exec mysqld --user=mysql --wsrep_cluster_name="$SHORT_CLUSTER_NAME" --wsrep_node_name="$hostname" \
    --wsrep_cluster_address="gcomm://$cluster_join" --wsrep_sst_method=xtrabackup-v2 \
    --wsrep_sst_auth="xtrabackup:$XTRABACKUP_PASSWORD" \
    --wsrep_node_address="$ipaddr" --pxc_strict_mode="$PXC_STRICT_MODE" "${CMDARG[@]}"
fi

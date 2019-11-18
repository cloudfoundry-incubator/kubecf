#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

default_name="kubecf-mysql"
printf "Name (%s): " "${default_name}"
read -r name
if [ -z "${name}" ]; then
  name="${default_name}"
fi

default_namespace="kubecf-mysql"
printf "Namespace (%s): " "${default_namespace}"
read -r namespace
if [ -z "${namespace}" ]; then
  namespace="${default_namespace}"
fi

stty -echo
printf "Root password: "
read -r root_password
stty echo
printf "\\n"
if [ -z "${root_password}" ]; then
  >&2 echo "The root password cannot be empty"
  exit 1
fi

databases=(
  "cloud_controller"
  "diego"
  "network_connectivity"
  "network_policy"
  "routing-api"
  "uaa"
  "locket"
  "credhub"
)

if ! "{KUBECTL}" get namespace "${namespace}" 1> /dev/null 2> /dev/null; then
  "{KUBECTL}" create namespace "${namespace}"
fi

"{HELM}" template "{MYSQL_CHART}" \
  --name "${name}" \
  --namespace "${namespace}" \
  --set "mysqlRootPassword=${root_password}" \
  --set "testFramework.enabled=false" \
  | "{KUBECTL}" apply -f - \
    --namespace "${namespace}"

"{KUBECTL}" wait --for condition=ready --namespace "${namespace}" pod --selector "app=${name}"

# Ensure the database is fully functional.
until echo "SELECT 'Ready!'" | "{KUBECTL}" run mysql-client --rm -i --restart='Never' --image docker.io/mysql --namespace "${namespace}" --command -- \
    mysql --host="${name}.${namespace}.svc" --user=root --password="${root_password}"; do
      sleep 1
done

cat <(
for database in ${databases[*]}; do
  echo "CREATE DATABASE IF NOT EXISTS \`${database}\`;"
done
) | "{KUBECTL}" run mysql-client --rm -i --restart='Never' --image docker.io/mysql --namespace "${namespace}" --command -- \
    mysql --host="${name}.${namespace}.svc" --user=root --password="${root_password}"

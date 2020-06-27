#!/usr/bin/env bash
source scripts/include/setup.sh

require_tools kubectl helm

: "${MYSQL_CHART:=https://kubernetes-charts.storage.googleapis.com/mysql-1.6.4.tgz}"
: "${MYSQL_CLIENT_IMAGE:=mysql@sha256:c93ba1bafd65888947f5cd8bd45deb7b996885ec2a16c574c530c389335e9169}"

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

if ! kubectl get namespace "${namespace}" 1> /dev/null 2> /dev/null; then
  kubectl create namespace "${namespace}"
fi

helm template "${name}" "${MYSQL_CHART}" \
  --namespace "${namespace}" \
  --set "mysqlRootPassword=${root_password}" \
  --set "testFramework.enabled=false" \
  | kubectl apply -f - \
    --namespace "${namespace}"

kubectl wait pod \
  --for condition=ready \
  --namespace "${namespace}" \
  --selector "app=${name}" \
  --timeout 300s

# Ensure the database is fully functional.
until echo "SELECT 'Ready!'" | kubectl run mysql-client --rm -i --restart='Never' --image "${MYSQL_CLIENT_IMAGE}" --namespace "${namespace}" --command -- \
    mysql --host="${name}.${namespace}.svc" --user=root --password="${root_password}"; do
      sleep 1
done

kubectl run mysql-client --rm -i --restart='Never' --image "${MYSQL_CLIENT_IMAGE}" --namespace "${namespace}" --command -- \
    mysql --host="${name}.${namespace}.svc" --user=root --password="${root_password}" \
    < <(
      for database in ${databases[*]}; do
        echo "CREATE DATABASE IF NOT EXISTS \`${database}\`;"
      done
    )

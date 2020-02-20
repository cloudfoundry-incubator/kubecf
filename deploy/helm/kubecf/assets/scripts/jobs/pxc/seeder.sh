#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

echo "Starting seeding..."
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

until echo "SELECT 'Ready!'" | mysql --host="${DATABASE_HOST}" --user=root --password="${DATABASE_ROOT_PASSWORD}"; do
  echo "database not ready.."
  sleep 1
done

mysql --host="${DATABASE_HOST}" --user=root --password="${DATABASE_ROOT_PASSWORD}" \
  < <(
    for database in ${databases[*]}; do
      password=$(</passwords/${database}/password)

      echo "CREATE USER \`${database}\` IDENTIFIED BY '${password}';"
      echo "CREATE DATABASE IF NOT EXISTS \`${database}\`;"
      echo "GRANT ALL ON \`${database}\`.* TO '${database}'@'%';"
    done
  )
echo "done."

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

echo "Waiting for database to be ready..."
until echo "SELECT 'Ready!'" | mysql --host="${DATABASE_HOST}" --user=root --password="${DATABASE_ROOT_PASSWORD}"; do
  sleep 1
done

mysql --host="${DATABASE_HOST}" --user=root --password="${DATABASE_ROOT_PASSWORD}" \
  1> /dev/null \
  2> /dev/null \
  < <(
    for database in ${databases[*]}; do
      password=$(</passwords/${database}/password)

      echo "CREATE USER \`${database}\` IDENTIFIED BY '${password}';"
      echo "CREATE DATABASE IF NOT EXISTS \`${database}\`;"
      echo "GRANT ALL ON \`${database}\`.* TO '${database}'@'%';"
    done
  )
echo "Done!"

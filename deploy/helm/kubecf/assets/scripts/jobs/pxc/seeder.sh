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
    echo "\
      CREATE DATABASE IF NOT EXISTS kubecf;
      USE kubecf;
      CREATE TABLE IF NOT EXISTS db_leader_election (
        anchor tinyint(3) unsigned NOT NULL,
        host varchar(128) NOT NULL,
        last_seen_active timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (anchor)
      );"
    for database in ${databases[*]}; do
      password=$(</passwords/"${database}"/password)

      echo "CREATE USER IF NOT EXISTS \`${database}\`;"
      echo "ALTER USER \`${database}\` IDENTIFIED BY '${password}';"
      echo "CREATE DATABASE IF NOT EXISTS \`${database}\`;"
      echo "GRANT ALL ON \`${database}\`.* TO '${database}'@'%';"
    done
  )
echo "Done!"

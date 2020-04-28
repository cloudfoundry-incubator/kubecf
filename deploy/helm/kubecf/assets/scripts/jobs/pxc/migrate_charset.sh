#!/usr/bin/env bash

# This script migrates the character set and collate of the KubeCF databases. This was originally
# introduced to migrate from latin1 to utf8 on existing installations up to v2.1.0.

set -o errexit -o nounset -o pipefail

echo "Waiting for database to be ready..."
until echo "SELECT 'Ready!'" | mysql --host="${DATABASE_HOST}" --user=root --password="${DATABASE_ROOT_PASSWORD}" --connect-timeout=3 2> /dev/null; do
  sleep 1
done

function alter_database() {
  local database=$1

  cat <<EOT
ALTER DATABASE \`${database}\`
  DEFAULT CHARACTER SET ${CHARACTER_SET}
  DEFAULT COLLATE ${COLLATE};

EOT

  echo "USE \`${database}\`;"
  echo "SET sql_mode = 'NO_AUTO_VALUE_ON_ZERO';"

  mysql \
    --host="${DATABASE_HOST}" \
    --user=root \
    --password="${DATABASE_ROOT_PASSWORD}" \
    --database="${database}" \
    --batch \
    --skip-column-names \
    --execute "SHOW TABLES" \
    | xargs --max-lines=1 --replace echo "SET foreign_key_checks = 0; ALTER TABLE \`{}\` CONVERT TO CHARACTER SET ${CHARACTER_SET} COLLATE ${COLLATE}; SET foreign_key_checks = 1;"

  echo -e "\n"
}

STATEMENT=$(
echo "START TRANSACTION;"

alter_database "mysql"
alter_database "kubecf"

for database in ${DATABASES}; do
  if [[ -z "${database}" ]]; then continue; fi
  alter_database "${database}"
done

echo "COMMIT;"
)

echo "${STATEMENT}" | mysql --host="${DATABASE_HOST}" --user=root --password="${DATABASE_ROOT_PASSWORD}"

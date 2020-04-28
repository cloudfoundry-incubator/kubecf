#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

echo "Waiting for database to be ready..."
until echo "SELECT 'Ready!'" | mysql --host="${DATABASE_HOST}" --user=root --password="${DATABASE_ROOT_PASSWORD}"; do
  sleep 1
done

CHARACTER_SET="utf8"
COLLATE="utf8_general_ci"

mysql --host="${DATABASE_HOST}" --user=root --password="${DATABASE_ROOT_PASSWORD}" \
  < <(
    echo "START TRANSACTION;"
    echo "\
      CREATE DATABASE IF NOT EXISTS kubecf;
      ALTER DATABASE kubecf
        DEFAULT CHARACTER SET ${CHARACTER_SET}
        DEFAULT COLLATE ${COLLATE};
      USE kubecf;
      CREATE TABLE IF NOT EXISTS db_leader_election (
        anchor tinyint(3) unsigned NOT NULL,
        host varchar(128) NOT NULL,
        last_seen_active timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (anchor)
      );"
    for database in ${DATABASES}; do
      if [[ -z "${database}" ]]; then continue; fi

      password=$(</passwords/"${database}"/password)

      echo "\
        CREATE USER IF NOT EXISTS \`${database}\`;
        ALTER USER \`${database}\` IDENTIFIED BY '${password}';

        CREATE DATABASE IF NOT EXISTS \`${database}\`;
        ALTER DATABASE \`${database}\`
          DEFAULT CHARACTER SET ${CHARACTER_SET}
          DEFAULT COLLATE ${COLLATE};

        GRANT ALL ON \`${database}\`.* TO '${database}'@'%';
      "
    done
    echo "COMMIT;"
  )
echo "Done!"

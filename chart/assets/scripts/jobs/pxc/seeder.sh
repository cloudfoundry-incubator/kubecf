#!/usr/bin/env bash

set -o errexit -o nounset -o pipefail

cat > "${HOME}/.my.cnf" <<EOF
[mysql]
host=${DATABASE_HOST}
user=root
password=${DATABASE_ROOT_PASSWORD}
EOF

echo "Waiting for database to be ready..."
until echo "SELECT 'Ready!'" | mysql --connect-timeout="${DATABASE_CONNECT_TIMEOUT}" 1> /dev/null 2> /dev/null; do
  sleep 1
done

mysql < <(
  echo "START TRANSACTION;"
  echo "\
    CREATE DATABASE IF NOT EXISTS kubecf
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

      CREATE DATABASE IF NOT EXISTS \`${database}\`
        DEFAULT CHARACTER SET ${CHARACTER_SET}
        DEFAULT COLLATE ${COLLATE};

      GRANT ALL ON \`${database}\`.* TO '${database}'@'%';
    "

    # Print out the name of the database for troubleshooting; this container
    # otherwise has very little output.
    echo "    ... will update database ${database}" >&2
  done
  echo "COMMIT;"
)
echo "Done!"

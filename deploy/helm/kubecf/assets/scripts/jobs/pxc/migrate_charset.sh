#!/usr/bin/env bash

# This script migrates the character set and collate of the KubeCF databases. This was originally
# introduced to migrate from latin1 to utf8 on existing installations up to v2.1.0.

set -o errexit -o nounset -o pipefail

cat > "${HOME}/.my.cnf" <<EOF
[mysql]
host=${DATABASE_HOST}
user=root
password=${DATABASE_ROOT_PASSWORD}
EOF

echo "Waiting for database to be ready..."
until echo "SELECT 'Ready!'" | mysql --connect-timeout=3 1> /dev/null 2> /dev/null; do
  sleep 1
done

function show_tables() {
  local database=$1
  mysql \
    --database="${database}" \
    --batch \
    --skip-column-names \
    --execute "SHOW TABLES"
}

function show_columns() {
  local database=$1
  local table=$2
  mysql \
    --database="${database}" \
    --batch \
    --skip-column-names \
    --execute "SHOW COLUMNS FROM ${table}"
}

function alter_tables() {
  local database=$1

  while read -r table; do
    >&2 echo "Generating statements for \`${database}\`.\`${table}\`..."

    echo "ALTER TABLE \`${table}\` DEFAULT CHARACTER SET ${CHARACTER_SET};"

    while read -r column; do
      field_type=$(awk --field-separator="\t" '{ print toupper($2) }' <<<"${column}")

      awk_program='/^(CHAR|VARCHAR|TINYTEXT|TEXT|MEDIUMTEXT|LONGTEXT|ENUM|SET)/ { print "modify" }'
      if [[ "$(awk "${awk_program}" <<<"${field_type}")" == "modify" ]]; then
        field_name=$(awk --field-separator="\t" '{ print $1 }' <<<"${column}")
        null_opt=$(awk --field-separator="\t" '{ print ($3 == "YES") ? "NULL" : "NOT NULL"}' <<<"${column}")
        field_default=$(awk --field-separator="\t" '{ print $5 }' <<<"${column}")
        if [[ "${field_default}" == "NULL" ]]; then
          if [[ "${null_opt}" == "NOT NULL" ]]; then
            default_opt=""
          else
            default_opt="DEFAULT NULL"
          fi
        else
          default_opt="DEFAULT '${field_default}'"
        fi

        echo "ALTER TABLE \`${table}\` MODIFY \`${field_name}\` ${field_type} CHARACTER SET ${CHARACTER_SET} ${null_opt} ${default_opt};"
      fi
    done < <(show_columns "${database}" "${table}")
  done < <(show_tables "${database}")
}

function get_charset() {
  local database=$1
  mysql \
    --database="${database}" \
    --batch \
    --skip-column-names \
    --execute "SELECT default_character_set_name FROM information_schema.SCHEMATA WHERE schema_name = '${database}';"
}

function alter_database() {
  local database=$1

  current_charset=$(get_charset "${database}")
  if [[ "${current_charset}" == "${CHARACTER_SET}" ]]; then
    return 0
  fi

  echo "ALTER DATABASE \`${database}\` DEFAULT CHARACTER SET ${CHARACTER_SET} DEFAULT COLLATE ${COLLATE};"
  echo "USE \`${database}\`;"
  echo "SET sql_mode = 'NO_AUTO_VALUE_ON_ZERO';"
  echo "SET foreign_key_checks = 0;"

  alter_tables "${database}"

  echo "SET foreign_key_checks = 1;"
  echo -e "\n"
}

STATEMENT=$(
echo "START TRANSACTION;"

alter_database "kubecf"

for database in ${DATABASES}; do
  if [[ -z "${database}" ]]; then continue; fi
  alter_database "${database}"
done

echo "COMMIT;"
)

mysql <<<"${STATEMENT}"

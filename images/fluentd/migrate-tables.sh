#!/bin/bash

set -e

CLICKHOUSE_CLIENT="clickhouse-client --host=${CLICKHOUSE_SERVER} --port=${CLICKHOUSE_PORT} --database="${CLICKHOUSE_DATABASE:-$CLICKHOUSE_DB}" --user=${CLICKHOUSE_USER} --password=${CLICKHOUSE_PASSWORD} --query"

DB_VERSION=`$CLICKHOUSE_CLIENT "SELECT MAX(version) FROM migrations"`

function migrate_v3 {
  echo "Start migration for v3"
  for table_name in `$CLICKHOUSE_CLIENT "SHOW TABLES" | grep -P "^${CLICKHOUSE_LOGS_TABLE}\d+"`; do
    echo "Processing ${table_name}..."
    $CLICKHOUSE_CLIENT "INSERT INTO ${CLICKHOUSE_LOGS_TABLE} SELECT * FROM ${table_name}"
    $CLICKHOUSE_CLIENT "DROP TABLE IF EXISTS ${table_name}"
  done
}

function migrate_v4 {
  echo "Start migration for v4"
  if [[ ! -z `$CLICKHOUSE_CLIENT "SHOW CREATE TABLE ${CLICKHOUSE_LOGS_TABLE}_old" 2>/dev/null` ]]; then
    for PART_NAME in `$CLICKHOUSE_CLIENT "SELECT DISTINCT(date) FROM ${CLICKHOUSE_LOGS_TABLE}_old"`; do
      echo "Processing ${PART_NAME}..."
      $CLICKHOUSE_CLIENT "INSERT INTO ${CLICKHOUSE_LOGS_TABLE} SELECT * FROM ${CLICKHOUSE_LOGS_TABLE}_old WHERE date = '${PART_NAME}'"
      $CLICKHOUSE_CLIENT "ALTER TABLE ${CLICKHOUSE_LOGS_TABLE}_old DROP PARTITION ${PART_NAME}"
    done
    $CLICKHOUSE_CLIENT "DROP TABLE IF EXISTS ${CLICKHOUSE_LOGS_TABLE}_old"
  fi
}

echo "Start migration to new schema"

case $DB_VERSION in
  0|1|2|3)
    migrate_v3
    ;;
  4)
    migrate_v3
    migrate_v4
    ;;
  *)
    echo "Unknown db version $DB_VERSION"
    ;;
esac
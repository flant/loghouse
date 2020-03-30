#!/bin/bash

set -e

CLICKHOUSE_CLIENT="clickhouse-client --host=${CLICKHOUSE_SERVER} --port=${CLICKHOUSE_PORT} --database="${CLICKHOUSE_DATABASE:-$CLICKHOUSE_DB}" --user=${CLICKHOUSE_USER} --password=${CLICKHOUSE_PASSWORD} --query"

DB_VERSION=`$CLICKHOUSE_CLIENT "SELECT MAX(version) FROM migrations"`

case $DB_VERSION in
  0|1|2|3)
    echo "Start migration to new schema"
    for table_name in `$CLICKHOUSE_CLIENT "SHOW TABLES" | grep -P "^${CLICKHOUSE_LOGS_TABLE}\d+"`; do
      echo "Processing ${table_name}..."
      $CLICKHOUSE_CLIENT "INSERT INTO ${CLICKHOUSE_LOGS_TABLE} SELECT * FROM ${table_name}"
      $CLICKHOUSE_CLIENT "DROP TABLE IF EXISTS ${table_name}"
    done
    ;;
  4)
    echo "Start migration to new schema"
    OLD_TABLE=`$CLICKHOUSE_CLIENT "SHOW TABLES" | grep -P "^${CLICKHOUSE_LOGS_TABLE}_old\$"`
    if [[ ! -z ${OLD_TABLE} ]]; then
      for PART_NAME in `$CLICKHOUSE_CLIENT "SELECT DISTINCT(date) FROM ${OLD_TABLE}"`; do
        echo "Processing ${PART_NAME}..."
        $CLICKHOUSE_CLIENT "INSERT INTO ${CLICKHOUSE_LOGS_TABLE} SELECT * FROM ${OLD_TABLE} WHERE date = '${PART_NAME}'"
        $CLICKHOUSE_CLIENT "ALTER TABLE ${OLD_TABLE} DROP PARTITION ${PART_NAME}"
      done
      $CLICKHOUSE_CLIENT "DROP TABLE IF EXISTS ${OLD_TABLE}"
    fi
    for table_name in `$CLICKHOUSE_CLIENT "SHOW TABLES" | grep -P "^${CLICKHOUSE_LOGS_TABLE}\d+"`; do
      echo "Processing ${table_name}..."
      $CLICKHOUSE_CLIENT "INSERT INTO ${CLICKHOUSE_LOGS_TABLE} SELECT * FROM ${table_name}"
      $CLICKHOUSE_CLIENT "DROP TABLE IF EXISTS ${table_name}"
    done
    ;;
  *)
    echo "Unknown db version $DB_VERSION"
    ;;
esac

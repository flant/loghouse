#!/bin/bash

CLICKHOUSE_CLIENT="clickhouse-client --host=${CLICKHOUSE_SERVER} --port=${CLICKHOUSE_PORT} -d ${CLICKHOUSE_DATABASE} --user=${CLICKHOUSE_USER} --password=${CLICKHOUSE_PASSWORD} --query"

DB_VERSION=`$CLICKHOUSE_CLIENT "SELECT MAX(version) FROM migrations"`

case $DB_VERSION in
  0|1|2|3)
    echo "Start migration to new schema"
    for table_name in `$CLICKHOUSE_CLIENT "SHOW TABLES" | grep -P "^${CLICKHOUSE_LOGS_TABLE}\d+"`; do
      echo $table_name
      $CLICKHOUSE_CLIENT "INSERT INTO ${CLICKHOUSE_LOGS_TABLE} SELECT * FROM ${table_name}"
      $CLICKHOUSE_CLIENT "DROP TABLE IF EXISTS ${table_name}"
      sleep 15
    done
    ;;
  *)
    echo "Unknown db version $DB_VERSION"
    ;;
esac

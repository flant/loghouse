#!/bin/bash

CLICKHOUSE_CLIENT="clickhouse-client --host=${CLICKHOUSE_URL} --port=${CLICKHOUSE_PORT} -d ${CLICKHOUSE_DATABASE} --user=${CLICKHOUSE_USER} --password=${CLICKHOUSE_PASSWORD} --query"

for table_name in `$CLICKHOUSE_CLIENT "SHOW TABLES" | grep -P "^${CLICKHOUSE_LOGS_TABLE}\d+'`; do
  echo $table_name
  $CLICKHOUSE_CLIENT "SELECT * FROM ${table_name} FORMAT TabSeparated" | $CLICKHOUSE_CLIENT "INSERT INTO ${CLICKHOUSE_LOGS_TABLE} FORMAT TabSeparated"
  $CLICKHOUSE_CLIENT "DROP TABLE IF EXISTS ${table_name}"
done

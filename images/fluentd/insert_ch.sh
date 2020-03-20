#!/bin/bash

cat $2 | clickhouse-client --host="${CLICKHOUSE_SERVER}" --port="${CLICKHOUSE_PORT}" --user="${CLICKHOUSE_USER}" --password=${CLICKHOUSE_PASSWORD} --database="${CLICKHOUSE_DATABASE:-$CLICKHOUSE_DB}" --compression true --query="INSERT INTO ${1} FORMAT JSONEachRow" && rm -f $2

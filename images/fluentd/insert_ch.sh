#!/bin/bash

cat $1 | clickhouse-client --host="${CLICKHOUSE_SERVER}" --port="${CLICKHOUSE_PORT}" --user="${CLICKHOUSE_USER}" --password=${CLICKHOUSE_PASS} --database="${CLICKHOUSE_DB}" --compression true --query="INSERT INTO logs FORMAT JSONEachRow" && rm -f $1

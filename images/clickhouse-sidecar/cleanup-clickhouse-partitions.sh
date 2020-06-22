#!/bin/bash

set -e

TARGET_PERCENT=${CLICLHOUSE_MAX_USE_PERCENT:-80}

CLICKHOUSE_CLIENT="clickhouse-client --host=${CLICKHOUSE_SERVER} --port=${CLICKHOUSE_PORT} --database="${CLICKHOUSE_DATABASE:-$CLICKHOUSE_DB}" --user=${CLICKHOUSE_USER} --password=${CLICKHOUSE_PASSWORD} --query"
CURRENT_PERCENT=$(/bin/df -h | awk '/\/var\/lib\/clickhouse/{print $5}')
CURRENT_PERCENT=${CURRENT_PERCENT//%/}

FLAG_FILE='/var/lib/clickhouse/flags/force_drop_table'

for PART_NAME in `$CLICKHOUSE_CLIENT "SELECT DISTINCT(partition) FROM system.parts WHERE database = '${CLICKHOUSE_DATABASE:-$CLICKHOUSE_DB}' AND table = '${K8S_LOGS_TABLE}' AND partition <> '$(date +%Y-%m-%d)' ORDER BY partition"`; do
  if [ "$CURRENT_PERCENT" -lt "$TARGET_PERCENT" ]; then
    break
  fi
  echo "CURRENT_PERCENT $CURRENT_PERCENT -gt TARGET_PERCENT $TARGET_PERCENT"
  echo "droping partitions ${PART_NAME} in table ${K8S_LOGS_TABLE}"
  touch ${FLAG_FILE} && chmod 666 ${FLAG_FILE}
  $CLICKHOUSE_CLIENT "ALTER TABLE ${K8S_LOGS_TABLE} DROP PARTITION '${PART_NAME}'"
  CURRENT_PERCENT=$(/bin/df -h |awk '/\/var\/lib\/clickhouse/{print $5}')
  CURRENT_PERCENT=${CURRENT_PERCENT//%/}
done

rm -f ${FLAG_FILE}
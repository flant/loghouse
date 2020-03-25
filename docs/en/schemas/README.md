# Loghouse clickhouse schemas

This is example sql schemas for clickhouse. More information in [clickhouse official docs](https://clickhouse.yandex/docs/en/)

## Clickhouse typical schemas

There are 2 typical setups:
* [Original Loghouse schema](original/README.md).
* [Cluster Loghouse schema](cluster/README.md).

## Clickhouse db version

Loghouse 0.3 using db version `3`. You can use new loghouse with previous db schema.
But new loghouse will be slow with old schema.

You should update using our helm chart, or do it manually.
```
DO_DB_DEPLOY=true rake create_logs_tables
``` 

## Using external Clickhouse

If you want to use external clickhouse set this variables in values.yaml
```
clickhouse:
  external: true
  externalEndpoints:
  - 10.0.0.1
  - 10.0.0.2
  - 10.0.0.3
```

For clickhouse cluster set this variable in values.yaml
```
doDbDeploy: false
```

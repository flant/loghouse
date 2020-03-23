Alternative loghouse clickhouse schema.

This schema is created for cluster deployments.
Additional configs situated in this directory.

Main configuration parameters for clickhouse in [config.xml](config.xml)
Clickhouse cluster `logs` configured in section `remote_servers`.

This cluster have ability for horizontal scaling.
You can add additional shards for:
* enlarging available space;
* increasing data processing speed;

**WARNING**  *Every node need unique macros set!*
* Macros `{shard}` should be unique for every shard
* Macros `{replica}` should be unique for node

You need to zookeeper connection for replication in shards and high
availability.

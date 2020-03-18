CREATE TABLE logs
(
    `date` Date DEFAULT toDate(NOW()), 
    `timestamp` DateTime, 
    `nsec` UInt32, 
    `source` String, 
    `namespace` String, 
    `host` String, 
    `pod_name` String, 
    `container_name` String, 
    `stream` String, 
    `labels.names` Array(String), 
    `labels.values` Array(String), 
    `string_fields.names` Array(String), 
    `string_fields.values` Array(String), 
    `number_fields.names` Array(String), 
    `number_fields.values` Array(Float64), 
    `boolean_fields.names` Array(String), 
    `boolean_fields.values` Array(Float64), 
    `null_fields.names` Array(String)
)
ENGINE = MergeTree()
PARTITION BY (date)
ORDER BY (timestamp, nsec, namespace, container_name)
TTL date + toIntervalDay(14)
SETTINGS index_granularity = 32768;

CREATE TABLE logs_buffer AS logs
ENGINE = Buffer(currentDatabase(), logs, 16, 10, 60, 1000, 10000, 1048576, 10485760);

CREATE TABLE queries_v1
(
    `id` FixedString(36), 
    `name` String, 
    `namespaces` Array(String), 
    `query` String, 
    `position` UInt8
)
ENGINE = TinyLog;

CREATE TABLE migrations
(
    `timestamp` DateTime, 
    `version` UInt32
)
ENGINE = MergeTree()
PARTITION BY timestamp
ORDER BY timestamp
SETTINGS index_granularity = 8192;


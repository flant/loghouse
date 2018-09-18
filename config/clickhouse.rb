config = {
  url: ENV.fetch('CLICKHOUSE_URL') { 'http://localhost:8123' },
  username: ENV.fetch('CLICKHOUSE_USERNAME') { nil },
  password: ENV.fetch('CLICKHOUSE_PASSWORD') { nil },
  database: LogsTables::DATABASE
}

Clickhouse.establish_connection config
LoghouseQuery.create_table_with_migration!

config = {
  url: ENV.fetch('CLICKHOUSE_URL') { 'http://localhost:8123' },
  username: ENV.fetch('CLICKHOUSE_USERNAME') { nil },
  password: ENV.fetch('CLICKHOUSE_PASSWORD') { nil },
  database: ENV.fetch('CLICKHOUSE_DATABASE') { 'logs' },
}

Clickhouse.establish_connection config

if !Clickhouse.connection.exists_table('queries')
  Clickhouse.connection.create_table("queries") do |t|
    t.fixed_string :id, 16
    t.string       :query
    t.engine       "TinyLog"
  end
end

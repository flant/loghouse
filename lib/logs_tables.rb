module LogsTables
  DATABASE            = ENV.fetch('CLICKHOUSE_DATABASE')            { 'logs' }
  TABLE_NAME          = ENV.fetch('CLICKHOUSE_LOGS_TABLE')          { 'logs' }
  TIMESTAMP_ATTRIBUTE = ENV.fetch('CLICKHOUSE_TIMESTAMP_ATTRIBUTE') { 'timestamp' }
  NSEC_ATTRIBUTE      = ENV.fetch('CLICKHOUSE_NSEC_ATTRIBUTE')      { 'nsec' }
  RETENTION_PERIOD    = ENV.fetch('LOGS_TABLES_RETENTION_PERIOD')   { '14' }.to_i
  HAS_BUFFER          = ENV.fetch('LOGS_TABLES_HAS_BUFFER')         { 'true' }
  PARTITION_PERIOD    = 1

  KUBERNETES_ATTRIBUTES = {
    source: 'String',
    namespace: 'String',
    host: 'String',
    pod_name: 'String',
    container_name: 'String',
    stream: 'String'
  }.freeze

  module_function

  def create_buffer_table(force: false)
    engine = "Buffer(#{DATABASE}, #{TABLE_NAME}, 16, 10, 60, 1000, 10000, 1048576, 10485760)"
    table_name = "#{TABLE_NAME}_buffer"

    create_table table_name, engine, force: force
  end

  def create_storage_table(force: false)
    engine = "MergeTree() PARTITION BY (date, toHour(#{TIMESTAMP_ATTRIBUTE})) ORDER BY (#{TIMESTAMP_ATTRIBUTE}, #{NSEC_ATTRIBUTE}, namespace, container_name) TTL date + INTERVAL #{RETENTION_PERIOD} DAY DELETE SETTINGS index_granularity=32768"
    table_name = TABLE_NAME

    create_table table_name, engine, force: force
  end

  def round_time_to_partition(time)
    Time.at(time.to_i / PARTITION_PERIOD.hours * PARTITION_PERIOD.hours).utc
  end

  def next_time_partition(time)
    round_time_to_partition(time) + PARTITION_PERIOD.hours
  end

  def prev_time_partition(time)
    round_time_to_partition(time) - PARTITION_PERIOD.hours
  end

  private

  module_function

  def create_table(table_name, engine, force: false)
    log "Creating table #{table_name}"

    if ::Clickhouse.connection.exists_table(table_name)
      log "Table #{table_name} exists", 6

      return unless force

      log "Force is true, so dropping table #{table_name}", 6

      ::Clickhouse.connection.drop_table(table_name)
    end

    ::Clickhouse.connection.execute create_table_sql(table_name, engine)

    log "Table #{table_name} created"
  end

  def create_table_sql(table_name, engine)
    <<~EOS
      CREATE TABLE #{table_name}
      (
        `date` Date MATERIALIZED toDate(#{TIMESTAMP_ATTRIBUTE}),
        `#{TIMESTAMP_ATTRIBUTE}` DateTime,
        `#{NSEC_ATTRIBUTE}` UInt64,
    #{KUBERNETES_ATTRIBUTES.map { |att, type| "    `#{att}` #{type}" }.join(",\n") },
        `labels` Nested (names String, values String),
        `string_fields` Nested (names String, values String),
        `number_fields` Nested (names String, values Float64),
        `boolean_fields` Nested (names String, values Float64),
        `null_fields.names` Array(String)
      ) ENGINE = #{engine}
    EOS
  end

  def log(msg, indent = 3)
    puts "#{'-' * indent}> #{msg}"
  end
end

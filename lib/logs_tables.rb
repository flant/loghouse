module LogsTables
  DATABASE              = ENV.fetch('CLICKHOUSE_DATABASE')            { 'logs' }
  LOGS_TABLE            = ENV.fetch('CLICKHOUSE_LOGS_TABLE')          { 'logs' }
  TIMESTAMP_ATTRIBUTE   = ENV.fetch('CLICKHOUSE_TIMESTAMP_ATTRIBUTE') { 'timestamp' }
  NSEC_ATTRIBUTE        = ENV.fetch('CLICKHOUSE_NSEC_ATTRIBUTE')      { 'nsec' }
  KUBERNETES_ATTRIBUTES = {
    namespace: 'String',
    host: 'String',
    pod_name: 'String',
    container_name: 'String',
    stream: 'String'
  }.freeze

  module_function

  def create_date_table(date = Date.today, force: false)
    engine = "MergeTree(date, (#{TIMESTAMP_ATTRIBUTE}, #{NSEC_ATTRIBUTE}), 32768)"
    table_name = date_table_name(date)

    create_table table_name, engine, force: force
  end

  def create_merge_table(force: false)
    engine = "Merge(#{DATABASE}, '^#{LOGS_TABLE}')"
    table_name = LOGS_TABLE

    create_table table_name, engine, force: force
  end

  private

  module_function
  def date_table_name(date = Date.today)
    "#{LOGS_TABLE}#{date.strftime('%Y%m%d')}"
  end

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
        `#{NSEC_ATTRIBUTE}` UInt32,
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

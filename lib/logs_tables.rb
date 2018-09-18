module LogsTables
  DATABASE            = ENV.fetch('CLICKHOUSE_DATABASE')            { 'logs' }
  TABLE_NAME          = ENV.fetch('CLICKHOUSE_LOGS_TABLE')          { 'logs' }
  TIMESTAMP_ATTRIBUTE = ENV.fetch('CLICKHOUSE_TIMESTAMP_ATTRIBUTE') { 'timestamp' }
  NSEC_ATTRIBUTE      = ENV.fetch('CLICKHOUSE_NSEC_ATTRIBUTE')      { 'nsec' }
  PARTITION_PERIOD    = ENV.fetch('LOGS_TABLES_PARTITION_PERIOD')   { '24' }.to_i

  raise "24 must be divisible by PARTITION_PERIOD" unless (24 % PARTITION_PERIOD).zero?

  KUBERNETES_ATTRIBUTES = {
    source: 'String',
    namespace: 'String',
    host: 'String',
    pod_name: 'String',
    container_name: 'String',
    stream: 'String'
  }.freeze

  module_function

  def create_partition_table(time = Tima.zone.now, force: false)
    engine = "MergeTree(date, (#{TIMESTAMP_ATTRIBUTE}, #{NSEC_ATTRIBUTE}), 32768)"
    table_name = partition_table_name(time)

    create_table table_name, engine, force: force
  end

  def create_merge_table(force: false)
    engine = "Merge(#{DATABASE}, '^#{TABLE_NAME}')"
    table_name = TABLE_NAME

    create_table table_name, engine, force: force
  end

  def partition_table_name(time = Time.now.utc)
    time = round_time_to_partition(time)

    "#{TABLE_NAME}#{time.strftime(PARTITION_PERIOD < 24 ? '%Y%m%d%H' : '%Y%m%d')}" # a little dirty
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

  def split_range_to_tables(time_from, time_to)
    table_ranges = {}
    time = round_time_to_partition time_from

    while time <= time_to do
      next_partition = next_time_partition(time)

      to = [time_to, next_partition].min
      from = [time_from, time].max

      table_ranges[partition_table_name(time)] = [from, to]

      time = next_partition
    end

    table_ranges
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

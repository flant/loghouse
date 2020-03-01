require_relative 'application'
# Dir.glob('lib/tasks/*.rake').each { |r| load r }

TRUE_VALUES = %w[1 on true]

Time.zone = Loghouse::TIME_ZONE

task :create_logs_tables do
  force = TRUE_VALUES.include?(ENV['FORCE'])
  do_db_deploy = TRUE_VALUES.include?(ENV['DO_DB_DEPLOY'])

  next unless do_db_deploy

  db_version = 0

  if ::Clickhouse.connection.exists_table(LogsTables::DB_VERSION_TABLE)
    db_version = ::Clickhouse.connection.query("SELECT MAX(version) AS version FROM #{LogsTables::DB_VERSION_TABLE}")[0][0]
  end

  puts "Got db version #{db_version}. Expected version #{LogsTables::DB_VERSION}"

  case db_version
  when 0..2
    LogsTables.create_storage_table(force: true)
    LogsTables.create_buffer_table(force: force)
    ::Clickhouse.connection.execute "INSERT INTO #{LogsTables::DB_VERSION_TABLE} VALUES (NOW(), #{LogsTables::DB_VERSION})"
  when 3
    ::Clickhouse.connection.execute "ALTER TABLE #{LogsTables::TABLE_NAME} MODIFY TTL date + toIntervalDay(#{LogsTables::RETENTION_PERIOD})"
  else
    puts "Unknown version #{db_version}. Nothing to do."
  end
end

task :insert_fixtures do
  s = CSV.generate do |csv|
    csv << [LogsTables::TIMESTAMP_ATTRIBUTE, LogsTables::NSEC_ATTRIBUTE, *LogsTables::KUBERNETES_ATTRIBUTES.keys,
      'labels.names', 'labels.values',
      'string_fields.names', 'string_fields.values','number_fields.names', 'number_fields.values',
      'boolean_fields.names', 'boolean_fields.values', 'null_fields.names']

    CSV.foreach('fixtures/fake_data.tsv', col_sep: "\t") do |r|
      time = rand(Range.new((LogsTables::RETENTION_PERIOD * 24).hours.ago.utc, Time.zone.now.utc))
      o = []
      o << time.strftime('%Y-%m-%d %H:%M:%S')
      o << rand(10**6).to_i
      o += r

      csv << o
    end
  end

  Clickhouse.connection.insert_rows(LogsTables::TABLE_NAME, csv: s)
end

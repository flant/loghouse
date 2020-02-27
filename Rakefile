require_relative 'application'
# Dir.glob('lib/tasks/*.rake').each { |r| load r }

TRUE_VALUES = %w[1 on true]

Time.zone = Loghouse::TIME_ZONE

task :create_logs_tables do
  force = TRUE_VALUES.include?(ENV['FORCE'])

  LogsTables.create_storage_table(force: force)
  LogsTables.create_buffer_table(force: force)
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

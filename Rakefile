require_relative 'application'
# Dir.glob('lib/tasks/*.rake').each { |r| load r }

TRUE_VALUES = %w[1 on true]

Time.zone = Loghouse::TIME_ZONE

task :create_logs do
  force = TRUE_VALUES.include?(ENV['FORCE'])

  LogsTables.create_merge_table(force: force)

  (0..6).each do |i|
    date = i.days.from_now
    LogsTables.create_date_table(date, force: force)
  end
end


task :insert_fixtures do
  s = CSV.generate do |csv|
    csv << [LogsTables::TIMESTAMP_ATTRIBUTE, LogsTables::NSEC_ATTRIBUTE, *LogsTables::KUBERNETES_ATTRIBUTES.keys,
            'labels.names', 'labels.values',
            'string_fields.names', 'string_fields.values','number_fields.names', 'number_fields.values',
            'boolean_fields.names', 'boolean_fields.values', 'null_fields.names']

    CSV.foreach('fixtures/fake_data.tsv', col_sep: "\t") do |r|
      o = []
      o << (Time.zone.now - rand(1_000).to_i.seconds).utc.strftime('%Y-%m-%d %H:%M:%S')
      o << rand(10**6).to_i
      o += r
      csv << o
    end
  end
  table = LogsTables.send(:date_table_name)

  Clickhouse.connection.insert_rows(table, csv: s)
end

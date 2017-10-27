require_relative 'application'
# Dir.glob('lib/tasks/*.rake').each { |r| load r }

TRUE_VALUES = %w[1 on true]

Time.zone = Loghouse::TIME_ZONE

task :create_logs_tables do
  force = TRUE_VALUES.include?(ENV['FORCE'])

  LogsTables.create_merge_table(force: force)

  time_to = 1.week.from_now.utc
  time = LogsTables.round_time_to_partition(Time.zone.now)

  while time <= time_to do
    LogsTables.create_partition_table(time, force: force)

    time = LogsTables.next_time_partition(time)
  end
end


task :insert_fixtures do
  tables_ranges = LogsTables.split_range_to_tables((LogsTables::PARTITION_PERIOD * 3).hours.ago.utc, Time.zone.now.utc)

  tables_ranges.each do |table, fromto|
    LogsTables.create_partition_table(fromto.first) unless ::Clickhouse.connection.exists_table(table)

    s = CSV.generate do |csv|
      csv << [LogsTables::TIMESTAMP_ATTRIBUTE, LogsTables::NSEC_ATTRIBUTE, *LogsTables::KUBERNETES_ATTRIBUTES.keys,
        'labels.names', 'labels.values',
        'string_fields.names', 'string_fields.values','number_fields.names', 'number_fields.values',
        'boolean_fields.names', 'boolean_fields.values', 'null_fields.names']

      CSV.foreach('fixtures/fake_data.tsv', col_sep: "\t") do |r|
        time = rand(Range.new(*fromto))
        o = []
        o << time.strftime('%Y-%m-%d %H:%M:%S')
        o << rand(10**6).to_i
        o += r

        csv << o
      end
    end

    Clickhouse.connection.insert_rows(table, csv: s)
  end
end

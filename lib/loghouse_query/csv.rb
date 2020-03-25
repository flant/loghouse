class LoghouseQuery
  module CSV
    def csv_result(shown_keys = nil)
      Log.log "Start csv function", 6
      sql = to_clickhouse(LogsTables::TABLE_NAME, parsed_time_from, parsed_time_to)
      res = LogEntry.from_result_set ::Clickhouse.connection.query(sql)

      Log.log "Got data from clickhouse", 6

      return "" if res.blank?

      Log.log "Start data conversion", 6
      res = res.map do |r|
        x = { 'timestamp' => r.timestamp.strftime("%Y-%m-%d %H:%M:%S.%N") }
        LogsTables::KUBERNETES_ATTRIBUTES.keys.each { |k| x[k.to_s] = r.send(k) }
        r.labels.each { |l, v| x["~#{l}"] = v }

        %w[strings numbers booleans].each do |a|
          r.send(a).each { |k, v| x[k.to_s] = v }
        end

        r.nulls.each { |k| x[k.to_s] = 'NULL' }
        x
      end.sort_by { |r| r['timestamp'] }

      names = res.map(&:keys).flatten.uniq
      names.select! { |n| (n == 'timestamp') || shown_keys.include?(n) } if shown_keys.present?

      ::CSV.generate do |csv|
        csv << names

        res.each do |r|
          csv << r.values_at(*names)
        end
      end
    end
  end
end

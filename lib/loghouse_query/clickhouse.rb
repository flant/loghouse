require 'loghouse_query/clickhouse/query'
require 'loghouse_query/clickhouse/expression'

class LoghouseQuery
  module Clickhouse
    extend ActiveSupport::Concern

    def result
      @result ||= begin
        if parsed_time_to.present?
          result_older(parsed_time_to, limit, parsed_time_from)
        elsif parsed_time_from.present? && parsed_time_to.blank?
          result_newer(parsed_time_from, limit)
        elsif parsed_seek_to.present?
          result_from_seek_to
        # else WTF
        end
      end
    end

    def to_clickhouse(table, from, to, lim = nil)
      params = {
        select: '*',
        from: table,
        order: order_by,
        limit: lim
      }
      if (where = to_clickhouse_where(from, to))
        params[:where] = where
      end

      ::Clickhouse.connection.to_select_query(params)
    end

    protected

    def result_older(start_time, lim, stop_at = nil)
      result = []
      time = start_time
      while lim.positive? && (stop_at.blank? || time >= stop_at)
        table = LogsTables.partition_table_name(time)
        break unless ::Clickhouse.connection.exists_table(table)

        sql = to_clickhouse(table, nil, start_time, lim)

        res = LogEntry.from_result_set ::Clickhouse.connection.query(sql)

        result += res
        lim -= res.count
        time = LogsTables.prev_time_partition(time)
      end
      result
    end

    def result_newer(start_time, lim, stop_at = nil)
      result = []
      time = start_time
      while lim.positive? && (stop_at.blank? || time <= stop_at)
        table = LogsTables.partition_table_name(time)
        break unless ::Clickhouse.connection.exists_table(table)

        sql = to_clickhouse(table, start_time, nil, lim)

        res = LogEntry.from_result_set ::Clickhouse.connection.query(sql)

        result += res.reverse
        lim -= res.count
        time = LogsTables.next_time_partition(time)
      end
      result.reverse
    end

    def result_from_seek_to
      lim = limit || Pagination::DEFAULT_PER_PAGE

      seek_to_max_periods = 2

      max_search_before = parsed_seek_to - (LogsTables::PARTITION_PERIOD.hours * seek_to_max_periods)
      max_search_after  = parsed_seek_to + (LogsTables::PARTITION_PERIOD.hours * seek_to_max_periods)
      max_search_after = Time.zone.now if max_search_after > Time.zone.now

      # search before part
      before = result_older(parsed_seek_to, lim, max_search_before)

      # search after part
      after = result_newer(parsed_seek_to, lim, max_search_after)

      res = after.last([before.count, lim / 2].min)
      res += before.first(lim - res.count)
      res
    end

    def time_comparation(time, comparation)
      if time.nsec.zero?
        "#{LogsTables::TIMESTAMP_ATTRIBUTE} #{comparation}= #{to_clickhouse_time(time)}"
      else
        '(' + [
          [
            [LogsTables::TIMESTAMP_ATTRIBUTE, to_clickhouse_time(time)].join(' = '),
            [LogsTables::NSEC_ATTRIBUTE, time.nsec].join(" #{comparation} ")
          ].join(' AND '),
          [LogsTables::TIMESTAMP_ATTRIBUTE, to_clickhouse_time(time)].join(" #{comparation} "),
        ].join(') OR (') + ')'
      end
    end

    def to_clickhouse_time(time)
      "toDateTime('#{time.utc.strftime('%Y-%m-%d %H:%M:%S')}')"
    end

    def to_clickhouse_namespaces
      return if namespaces.blank?

      namespaces.map { |ns| "namespace = '#{ns}'" }.join(' OR ')
    end

    def to_clickhouse_where(from = nil, to = nil)
      where_parts = []
      where_parts << Query.new(parsed_query[:query]).to_s if parsed_query

      where_parts << time_comparation(from, '>') if from
      where_parts << time_comparation(to, '<') if to

      where_parts << to_clickhouse_namespaces
      where_parts.compact!

      return if where_parts.blank?

      "(#{where_parts.join(') AND (')})"
    end
  end
end

require 'loghouse_query/clickhouse/query'
require 'loghouse_query/clickhouse/expression'

class LoghouseQuery
  module Clickhouse
    extend ActiveSupport::Concern

    def result
      @result ||= begin
        lim = limit
        split_range_to_tables.sort_by {|table, fromto| fromto.last }.reverse.map do |table, fromto|
          next unless lim.positive? && ::Clickhouse.connection.exists_table(table)

          sql = to_clickhouse(table, *fromto, lim)

          res = LogEntry.from_result_set ::Clickhouse.connection.query(sql)

          lim -= res.count
          res
        end.compact.flatten
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

    def split_range_to_tables
      LogsTables.split_range_to_tables(parsed_time_from, parsed_time_to)
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

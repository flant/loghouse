require 'loghouse_query/clickhouse/query'
require 'loghouse_query/clickhouse/expression'

class LoghouseQuery
  module Clickhouse
    extend ActiveSupport::Concern

    def to_clickhouse
      params = {
        select: '*',
        from: LogsTables::LOGS_TABLE,
        order: order_by,
        limit: limit
      }
      if (where = to_clickhouse_where)
        params[:where] = where
      end

      params
    end

    protected

    def to_clickhouse_time(time)
      time = Time.zone.parse(time) if time.is_a? String

      "toDateTime('#{time.utc.strftime('%Y-%m-%d %H:%M:%S')}')"
    end

    def to_clickhouse_where
      where_parts = []
      where_parts << Query.new(parsed_query[:query]).to_s if parsed_query

      where_parts << "#{LogsTables::TIMESTAMP_ATTRIBUTE} >= #{to_clickhouse_time parsed_time_from}" if parsed_time_from
      where_parts << "#{LogsTables::TIMESTAMP_ATTRIBUTE} <= #{to_clickhouse_time parsed_time_to}" if parsed_time_to

      where_parts << to_clickhouse_pagination_where
      where_parts.compact!

      return if where_parts.blank?

      "(#{where_parts.join(') AND (')})"
    end
  end
end

class LoghouseQuery
  module Clickhouse
    class Query
      attr_reader :query
      def initialize(query, operator = nil)
        @query    = query
        @operator = operator
      end

      def subquery
        return if query[:subquery].blank?

        @subquery ||= self.class.new(query[:subquery][:query], query[:subquery][:q_op])
      end

      def operator
        @operator.to_s.upcase
      end

      def to_s
        result = "(#{Expression.new(query[:expression]).to_s})"

        result = [result, "#{subquery.operator}\n", subquery.to_s].join(' ') if subquery
        result
      end
    end
  end
end

require 'loghouse_query_p'
require 'loghouse_query_time_p'

class LoghouseQuery
  class BadFormat < StandardError; end
  class BadTimeFormat < StandardError; end

  TABLE               = ENV.fetch('CLICKHOUSE_TABLE') { 'logs6' }
  TIMESTAMP_ATTRIBUTE = ENV.fetch('CLICKHOUSE_TIMESTAMP_ATTRIBUTE') { 'timestamp' }

  def self.parser
    @@parslet ||= LoghouseQueryP.new
  end

  def self.time_parser
    @@time_parslet ||= LoghouseQueryTimeP.new
  end

  attr_accessor :raw_query, :parsed_query

  def initialize(raw_query, time_from, time_to, page=nil)
    @raw_query = raw_query
    @time_from = time_parser.parse_time(time_from) if time_from.present?
    @time_to   = time_parser.parse_time(time_to) if time_to.present?

    return if @raw_query.to_s.blank?

    begin
      @parsed_query = parser.parse raw_query
    rescue Parslet::ParseFailed => e
      raise BadFormat.new("#{raw_query}: #{e}")
    end
  end

  def parser
    self.class.parser
  end

  def time_parser
    self.class.time_parser
  end

  def to_clickhouse
    params = {
      select: '*',
      from: TABLE
    }
    if (where = to_clickhouse_where)
      params[:where] = where
    end

    params
  end

  protected

  def to_clickhouse_time(time)
    "toDateTime('#{time.utc.strftime('%Y-%m-%d %H:%M:%S')}')"
  end

  def to_clickhouse_where
    where_parts = []
    where_parts << query_to_clickhouse(parsed_query[:query]) if @parsed_query

    where_parts << "#{TIMESTAMP_ATTRIBUTE} >= #{to_clickhouse_time @time_from}" if @time_from
    where_parts << "#{TIMESTAMP_ATTRIBUTE} <= #{to_clickhouse_time @time_to}" if @time_to

    return if where_parts.blank?

    "(#{where_parts.join(') AND (')})"
  end


  def query_to_clickhouse(query)
    result = "(#{expression_to_clickhouse(query[:expression])})"

    if query[:subquery]
      op = query_operator_to_clickhouse(query[:subquery][:q_op])
      query_result = query_to_clickhouse(query[:subquery][:query])

      result = [result, "#{op}\n", query_result].join(' ')
    end

    result
  end

  def expression_to_clickhouse(expression)
    op =  if expression[:not_null]
            'not_null'
          elsif expression[:is_null]
            'is_null'
          elsif expression[:is_true]
            'is_true'
          elsif expression[:is_false]
            'is_false'
          else
            expression[:e_op]
          end

    key = expression[:key]
    str_val = expression[:str_value]
    num_val = expression[:num_value]

    case op
    when 'not_null', 'is_null'
      "#{'NOT ' if op == 'not_null'}has(null_fields.names, '#{key}')"
    when 'is_true', 'is_false'
      "has(boolean_fields.names, '#{key}') AND boolean_fields.values[indexOf(boolean_fields.names, '#{key}')] = #{op == 'is_true' ? 1 : 0}"
    when '>', '<', '<=', '>='
      val = (num_val || str_val).to_f
      "has(number_fields.names, '#{key}') AND number_fields.values[indexOf(number_fields.names, '#{key}')] #{op} #{val}"
    when '=~'
      val = (str_val || num_val).to_s
      val = "/#{val}/" unless val =~ /\/.*\//

      "has(string_fields.names, '#{key}') AND match(string_fields.values[indexOf(string_fields.names, '#{key}')], '#{val}')"
    when '=', '!='
      if (val = str_val)
        val = val.to_s
        if val.include?('%') || val.include?('_')
          "has(string_fields.names, '#{key}') AND #{op == '=' ? 'like' : 'notLike'}(string_fields.values[indexOf(string_fields.names, '#{key}')],'#{val}')"
        else
          "has(string_fields.names, '#{key}') AND string_fields.values[indexOf(string_fields.names, '#{key}')] #{op} '#{val}'"
        end
      else
        val = num_val
        <<~EOS
          CASE
            WHEN has(string_fields.names, '#{key}')
              THEN string_fields.values[indexOf(string_fields.names, '#{key}')] = '#{val}'
            WHEN has(number_fields.names, '#{key}')
              THEN number_fields.values[indexOf(number_fields.names, '#{key}')] = #{val}
            ELSE 0
          END
        EOS
      end
    end
  end

  def query_operator_to_clickhouse(op)
    op.to_s.upcase
  end
end

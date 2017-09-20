require 'loghouse_query_p'
class LoghouseQuery
  class BadFormat < StandardError; end

  def self.parser
    @@parslet ||= LoghouseQueryP.new
  end

  attr_accessor :raw_query, :parsed_query

  def initialize(raw_query)
    @raw_query = raw_query

    begin
      @parsed_query = parser.parse raw_query
    rescue Parslet::ParseFailed => e
      raise BadFormat.new("#{raw_query}: #{e.to_s}")
    end
  end

  def parser
    self.class.parser
  end

  def to_clickhouse
    <<~EOS
      SELECT * FROM logs.logs6 WHERE (
        #{query_to_clickhouse(parsed_query[:query])}
      );
    EOS
  end

  protected

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
          else expression[:e_op]
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
        "has(string_fields.names, '#{key}') AND string_fields.values[indexOf(string_fields.names, '#{key}')] #{op} '#{val}'"
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

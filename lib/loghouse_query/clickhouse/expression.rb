class LoghouseQuery
  module Clickhouse
    class Expression
      attr_reader :key, :value, :operator
      def initialize(expression, operator = nil)
        @any_key  = expression[:any_key]
        @key      = expression[:key]
        @value    = expression[:str_value].to_s.presence || expression[:num_value].to_f
        @operator = if expression[:not_null]
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
      end

      def any_key?
        @any_key.present?
      end

      def to_s
        case operator
        when 'not_null', 'is_null'
          null
        when 'is_true', 'is_false'
          boolean
        when '>', '<', '<=', '>='
          number_comparison
        when '=~'
          string_regex
        when '=', '!='
          if (value.is_a?(String))
            equation_string
          else
            equation_all
          end
        end
      end

      private

      def null
        "#{'NOT ' if operator == 'not_null'}has(null_fields.names, '#{key}')"
      end

      def boolean
        "has(boolean_fields.names, '#{key}') AND "\
        "boolean_fields.values[indexOf(boolean_fields.names, '#{key}')] = #{operator == 'is_true' ? 1 : 0}"
      end

      def number_comparison
        if any_key?
          "arrayExists(x -> x #{operator} #{value.to_f}, number_fields.values)"
        else
          "has(number_fields.names, '#{key}') AND "\
          "number_fields.values[indexOf(number_fields.names, '#{key}')] #{operator} #{value.to_f}"
        end
      end

      def string_regex
        val = value.to_s
        val.gsub!(/\//, '')

        if any_key?
          "arrayExists(x -> match(x, '#{val}'), string_fields.values)"
        else
          "has(string_fields.names, '#{key}') AND "\
          "match(string_fields.values[indexOf(string_fields.names, '#{key}')], '#{val}')"
        end
      end

      def equation_string
        if value.include?('%') || value.include?('_')
          if any_key?
            "arrayExists(x -> #{operator == '=' ? 'like' : 'notLike'}(x, '#{value}'), string_fields.values)"
          else
            "has(string_fields.names, '#{key}') AND "\
            "#{operator == '=' ? 'like' : 'notLike'}(string_fields.values[indexOf(string_fields.names, '#{key}')], '#{value}')"
          end
        else
          if any_key?
            "arrayExists(x -> x #{operator} '#{value}', string_fields.values)"
          else
            "has(string_fields.names, '#{key}') AND "\
            "string_fields.values[indexOf(string_fields.names, '#{key}')] #{operator} '#{value}'"
          end
        end
      end

      def equation_all
        if any_key?
          "arrayExists(x -> x #{operator} '#{value}', string_fields.values) OR "\
          "arrayExists(x -> x #{operator} #{value}, number_fields.values)"
        else
          <<~EOS
            CASE
              WHEN has(string_fields.names, '#{key}')
                THEN string_fields.values[indexOf(string_fields.names, '#{key}')] #{operator} '#{value}'
              WHEN has(number_fields.names, '#{key}')
                THEN number_fields.values[indexOf(number_fields.names, '#{key}')] #{operator} #{value}
              ELSE 0
            END
          EOS
        end
      end
    end
  end
end

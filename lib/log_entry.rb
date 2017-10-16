class LogEntry
  def self.from_result_set(result_set)
    result_set.map { |r| new r, result_set.names }
  end

  attr_reader :timestamp, :strings, :numbers, :booleans, :nulls
  LoghouseQuery::KUBERNETES_ATTRIBUTES.keys.each { |k| attr_reader k }

  def initialize(row, names)
    @names          = names
    @row            = row
    @timestamp      = row[names.index('timestamp')].change(nsec: row[names.index('nsec')])

    LoghouseQuery::KUBERNETES_ATTRIBUTES.keys.each do |k|
      instance_variable_set("@#{k}", row[names.index(k.to_s)])
    end

    @strings  = fields_to_hash('string')
    @numbers  = fields_to_hash('number')  { |v| v.to_i }
    @booleans = fields_to_hash('boolean') { |v| v.to_i == 1 }
    @nulls    = row[names.index('null_fields.names')].map(&:to_sym)
  end

  protected

  def fields_to_hash(name)
    res      = {}
    f_names  = @row[@names.index("#{name}_fields.names")]
    f_values = @row[@names.index("#{name}_fields.values")]
    f_names.each_with_index do |n, i|
      v = f_values[i]
      res[n.to_sym] = block_given? ? yield(v) : v
    end
    res
  end
end

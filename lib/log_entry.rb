class LogEntry
  def self.from_result_set(result_set)
    result_set.map { |r| new r.to_hash }
  end

  attr_reader :timestamp, :labels, :strings, :numbers, :booleans, :nulls
  LogsTables::KUBERNETES_ATTRIBUTES.keys.each { |k| attr_reader k }

  def initialize(row)
    @row       = row
    @timestamp = row['timestamp'].change(nsec: row['nsec'])

    LogsTables::KUBERNETES_ATTRIBUTES.keys.each do |k|
      instance_variable_set("@#{k}", row[k.to_s])
    end

    @labels   = fields_to_hash('labels')
    @strings  = fields_to_hash('string_fields')
    @numbers  = fields_to_hash('number_fields')  { |v| v.to_i }
    @booleans = fields_to_hash('boolean_fields') { |v| v.to_i == 1 }
    @nulls    = row['null_fields.names'].map(&:to_sym)
  end

  protected

  def fields_to_hash(name)
    res      = {}
    f_names  = @row["#{name}.names"]
    f_values = @row["#{name}.values"]
    f_names.each_with_index do |n, i|
      v = f_values[i]
      res[n.to_sym] = block_given? ? yield(v) : v
    end
    res
  end
end

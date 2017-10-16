require 'loghouse_query/parsers'
require 'loghouse_query/storable'
require 'loghouse_query/pagination'
require 'loghouse_query/clickhouse'

class LoghouseQuery
  include Parsers
  include Storable
  include Pagination
  include Clickhouse

  LOGS_TABLE            = ENV.fetch('CLICKHOUSE_LOGS_TABLE')          { 'logs' }
  TIMESTAMP_ATTRIBUTE   = ENV.fetch('CLICKHOUSE_TIMESTAMP_ATTRIBUTE') { 'timestamp' }
  NSEC_ATTRIBUTE        = ENV.fetch('CLICKHOUSE_NSEC_ATTRIBUTE')      { 'nsec' }
  KUBERNETES_ATTRIBUTES = {
    namespace: 'String',
    host: 'String',
    pod_name: 'String',
    container_name: 'String',
    stream: 'String'
  }.freeze

  DEFAULTS = {
    id:        nil,
    name:      nil,
    query:     nil,
    time_from: 'now-12h',
    time_to:   'now',
    position:  nil
  }.freeze # Trick for all-attributes-hash in correct order in insert

  attr_accessor :attributes

  def initialize(attrs = {})
    attrs.symbolize_keys!
    @attributes = DEFAULTS.dup
    @attributes.each do |k, v|
      @attributes[k] = attrs[k] if attrs[k].present?
    end
    @attributes[:id] ||= SecureRandom.uuid
  end

  def id
    attributes[:id]
  end

  def order_by
    [attributes[:order_by], "#{TIMESTAMP_ATTRIBUTE} DESC", "#{NSEC_ATTRIBUTE} DESC"].compact.join(', ')
  end

  def result
    @result ||= LogEntry.from_result_set ::Clickhouse.connection.select_rows(to_clickhouse)
  end

  def validate!
    to_clickhouse # sort of validation: will fail if queries is not correct

    super
  end
end

require 'log_entry'

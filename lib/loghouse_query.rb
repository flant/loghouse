require 'loghouse_query/parsers'
require 'loghouse_query/storable'
require 'loghouse_query/pagination'
require 'loghouse_query/clickhouse'
require 'loghouse_query/permissions'
require 'loghouse_query/csv'
require 'log_entry'

class LoghouseQuery
  include Parsers
  include Storable
  include Pagination
  include Clickhouse
  include Permissions
  include CSV

  DEFAULTS = {
    id:         nil,
    name:       nil,
    namespaces: [],
    query:      nil,
    time_from:  'now-12h',
    time_to:    'now',
    position:   nil
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

  def namespaces
    attributes[:namespaces]
  end

  def order_by
    [attributes[:order_by], "#{LogsTables::TIMESTAMP_ATTRIBUTE} DESC", "#{LogsTables::NSEC_ATTRIBUTE} DESC"].compact.join(', ')
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

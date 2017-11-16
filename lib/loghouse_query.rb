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
    position:   nil
  }.freeze # Trick for all-attributes-hash in correct order in insert

  TIME_PARAMS_DEFAULTS = {
    format:  'seek_to',
    seek_to: 'now',
    from:    'now-15m',
    to:      'now'
  }.freeze

  attr_accessor :attributes, :time_params, :persisted

  def initialize(attrs = {})
    attrs.symbolize_keys!
    @attributes = DEFAULTS.dup
    @attributes.each do |k, v|
      @attributes[k] = attrs[k] if attrs[k].present?
    end
    @attributes[:id] ||= SecureRandom.uuid
    time_params({})
  end

  def time_params(params=nil)
    return @time_params if params.nil?

    @time_params = TIME_PARAMS_DEFAULTS.dup
    params.each do |k, v|
      @time_params[k] = params[k] if params[k].present?
    end

    case @time_params[:format]
    when 'seek_to'
      @time_params.slice!(:format, :seek_to)
    when 'range'
      @time_params.slice!(:format, :from, :to)
    end
    self
  end

  def id
    attributes[:id]
  end

  def namespaces
    Array.wrap(attributes[:namespaces])
  end

  def order_by
    [attributes[:order_by], "#{LogsTables::TIMESTAMP_ATTRIBUTE} DESC", "#{LogsTables::NSEC_ATTRIBUTE} DESC"].compact.join(', ')
  end

  def validate_query!
    parsed_query # sort of validation: will fail if format is not correct
  end

  def validate_time_params!
    if time_params[:format] == 'range'
      parsed_time_from # sort of validation: will fail if format is not correct
      parsed_time_to # sort of validation: will fail if format is not correct
    else
      parsed_seek_to # sort of validation: will fail if format is not correct
    end
  end

  def validate!(options = {})
    super

    validate_query! unless options[:query] == false
    validate_time_params! unless options[:time_params] == false
  end
end

require 'log_entry'

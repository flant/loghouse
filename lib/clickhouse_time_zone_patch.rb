module ClickhouseTimeZonePatch
  def parse_date_time_value(value)
    ActiveSupport::TimeZone.new('UTC').parse(value).in_time_zone(Time.zone)
  end
end

Clickhouse::Connection::Query::ResultSet.send(:prepend, ClickhouseTimeZonePatch)

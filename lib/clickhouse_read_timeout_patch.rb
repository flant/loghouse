module ClickhouseReadTimeoutPatch
  def client
    @client ||= Faraday.new(url: url) do |f|
      f.adapter :net_http do |http|
        http.read_timeout = ENV.fetch('CLICKHOUSE_READ_TIMEOUT') { '1800' }.to_i
      end
    end
  end
end

Clickhouse::Connection.send(:include, ClickhouseReadTimeoutPatch)

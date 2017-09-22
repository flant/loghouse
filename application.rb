require_relative 'config/boot'

module Loghouse
  TIME_ZONE = 'Europe/Moscow'

  # rubocop:disable Metrics/ClassLength
  class Application < Sinatra::Base
    configure do
      enable :logging
    end

    before do
      Time.zone = TIME_ZONE
    end

    get '/' do
      erb :index
    end

    get '/query' do
      begin
        @loghouse_query = LoghouseQuery.new(params[:q].to_s, params[:time_from], params[:time_to])
        @rows = Clickhouse.connection.select_rows(@loghouse_query.to_clickhouse)
      rescue LoghouseQuery::BadFormat => e
        @error = "Bad query format: #{e}"
      rescue LoghouseQuery::BadTimeFormat => e
        @error = "Bad time format: #{e}"
      end
      erb :index
    end

    helpers do
      def h(text)
        Rack::Utils.escape_html(text)
      end
    end
  end
end

require_relative 'config/boot'

module Loghouse
  # rubocop:disable Metrics/ClassLength
  class Application < Sinatra::Base
    configure do
      enable :logging
    end

    get '/' do
      erb :index
    end

    get '/query' do
      begin
        @loghouse_query = LoghouseQuery.new(params[:q].to_s)
      rescue LoghouseQuery::BadFormat
        @error = 'Bad query format!'
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

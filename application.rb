require_relative 'config/boot'

module Loghouse
  TIME_ZONE = 'Europe/Moscow'

  # rubocop:disable Metrics/ClassLength
  class Application < Sinatra::Base
    configure do
      register WillPaginate::Sinatra

      enable :logging
    end

    before do
      Time.zone = TIME_ZONE
    end

    get '/' do
      @queries = LoghouseQuery.all
      erb :index
    end

    get '/query' do
      @queries = LoghouseQuery.all
      @query =  if params[:query_id]
                  LoghouseQuery.find!(params[:query_id])
                else
                  query_from_params
                end

      begin
        @query.paginate(page: params[:page], per_page: params[:per_page])
        @to_clickhouse = @query.to_clickhouse
      rescue LoghouseQuery::BadFormat => e
        @error = "Bad query format: #{e}"
      rescue LoghouseQuery::BadTimeFormat => e
        @error = "Bad time format: #{e}"
      end

      if request.xhr?
        erb :_result, layout: false
      else
        erb :index
      end
    end

    # Queries management
    before '/queries*' do
      @tab = :queries
    end

    get '/queries' do
      @queries = LoghouseQuery.all

      erb :'queries/index'
    end

    get '/queries/new' do
      @query = query_from_params
      erb :'queries/new'
    end

    post '/queries' do
      @query = query_from_params

      @query.save!

      redirect '/queries'
    end

    delete '/queries' do
      LoghouseQuery.create_table!(true)

      body ''
    end

    helpers do
      def h(text)
        Rack::Utils.escape_html(text)
      end
    end

    private

    def query_from_params
      LoghouseQuery.new(name: params[:name], query: params[:query].to_s,
                        time_from: params[:time_from], time_to: params[:time_to],
                        follow: (params[:follow] == 'on') ? 1 : 0)
    end
  end
end

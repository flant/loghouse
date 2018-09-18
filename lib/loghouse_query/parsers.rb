require 'loghouse_query_p'
require 'loghouse_query_time_p'

class LoghouseQuery
  class BadFormat < StandardError; end
  class BadTimeFormat < StandardError; end

  module Parsers
    extend ActiveSupport::Concern

    module ClassMethods
      def parser
        @@parser ||= LoghouseQueryP.new
      end

      def time_parser
        @@time_parser ||= LoghouseQueryTimeP.new
      end
    end

    def parser
      self.class.parser
    end

    def time_parser
      self.class.time_parser
    end

    def parsed_time_from
      @parsed_time_from ||= time_parser.parse_time(time_params[:from]) if time_params[:from].present?
    end

    def parsed_time_to
      @parsed_time_to ||= time_parser.parse_time(time_params[:to]) if time_params[:to].present?
    end

    def parsed_seek_to
      @parsed_seek_to ||= begin
        return if time_params[:seek_to].blank?

        time = Chronic.parse(time_params[:seek_to])

        raise BadTimeFormat.new("Unable to parse seek_to '#{time_params[:seek_to]}'") if time.nil?
        time
      end
    end

    def parsed_query
      return if attributes[:query].blank?

      @parsed_query ||= begin
        parser.parse attributes[:query]
      rescue Parslet::ParseFailed => e
        raise BadFormat.new("#{attributes[:query]}: #{e}")
      end
    end

    def parse!
      parsed_query
      parsed_time_to
      parsed_time_from
    end
  end
end

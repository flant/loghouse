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
      @parsed_time_from ||= time_parser.parse_time(attributes[:time_from]) if attributes[:time_from].present?
    end

    def parsed_time_to
      @parsed_time_to ||= time_parser.parse_time(attributes[:time_to]) if attributes[:time_to].present?
    end

    def parsed_seek_to
      @parsed_seek_to ||= begin
        return if attributes[:seek_to].blank?

        time = Chronic.parse(attributes[:seek_to])

        raise BadTimeFormat.new("Unable to parse seek_to '#{attributes[:seek_to]}'") if time.nil?
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

require 'loghouse_query/table'

class LoghouseQuery
  module Storable
    class NotValid < StandardError; end
    class NotFound < StandardError; end

    extend ActiveSupport::Concern

    included do
      include Table
    end

    module ClassMethods
      def count(params = {})
        params.merge!({
          from: table_name
        })

        ::Clickhouse.connection.count(params)
      end

      def all(params = {})
        params.merge!({
          select: '*',
          from: table_name,
          order: 'position ASC'
        })

        ::Clickhouse.connection.select_rows(params).map { |r| build_from_row r }
      end

      def find(id)
        if (row = ::Clickhouse.connection.select_row(select: '*', from: table_name, where: { id: id }))
          build_from_row row
        end
      end

      def find!(id)
        find(id) || raise(NotFound.new("Record with id='#{id} not found!'"))
      end

      def update_order!(new_order)
        all_queries = self.all

        all_queries.each do |q|
          q.attributes[:position] = new_order.index(q.id)
        end

        create_table!(true)
        all_queries.each(&:save!)
      end

      protected

      def build_from_row(row)
        attrs = {}
        columns.keys.each_with_index do |c, i|
          attrs[c] = row[i]
        end

        lq = new attrs
        lq.persisted = true
        lq
      end
    end

    def destroy!
      all_queries = self.class.all
      all_queries.reject!{ |q| q.id == id }

      self.class.create_table!(force: true)

      all_queries.each(&:save!)
    end

    def update!(attrs)
      attributes.merge!(attrs.except(:id, :position))
      validate!

      destroy!
      save!
    end

    def save!
      validate!

      return false unless self.class.find(id).blank?

      attributes[:position]   ||= self.class.count
      attributes[:namespaces] = attributes[:namespaces].to_s.gsub(/"/, "'") # KOSTYL for bad working with arrays in gem

      ::Clickhouse.connection.insert_rows self.class.table_name do |rows|
        rows << attributes
      end
    end

    def validate!(options = {})
      raise NotValid.new('Name cannot be blank!') if options[:name] != false && attributes[:name].blank?
    end
  end
end

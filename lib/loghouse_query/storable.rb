class LoghouseQuery
  QUERIES_TABLE = ENV.fetch('CLICKHOUSE_QUERIES_TABLE') { 'queries' }

  module Storable
    class NotValid < StandardError; end
    class NotFound < StandardError; end

    extend ActiveSupport::Concern

    module ClassMethods
      def create_table!(force = false)
        if ::Clickhouse.connection.exists_table(QUERIES_TABLE)
          return unless force

          ::Clickhouse.connection.drop_table(QUERIES_TABLE)
        end

        ::Clickhouse.connection.create_table(QUERIES_TABLE) do |t|
          t.fixed_string :id, 36
          t.string       :name
          t.string       :query
          t.string       :time_from
          t.string       :time_to
          t.uint8        :position
          t.engine       "TinyLog"
        end
      end

      def count(params = {})
        params.merge!({
          from: QUERIES_TABLE
        })

        ::Clickhouse.connection.count(params)
      end

      def all(params = {})
        params.merge!({
          select: '*',
          from: QUERIES_TABLE,
          order: 'position ASC'
        })

        ::Clickhouse.connection.select_rows(params).map { |r| build_from_row r }
      end

      def find(id)
        if (row = ::Clickhouse.connection.select_row(select: '*', from: QUERIES_TABLE, where: { id: id }))
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
        new id: row[0], name: row[1], query: row[2], time_from: row[3], time_to: row[4], position: row[5]
      end
    end

    def destroy!
      all_queries = self.class.all
      all_queries.reject!{ |q| q.id == id }

      self.class.create_table!(true)

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

      attributes[:position] ||= self.class.count

      ::Clickhouse.connection.insert_rows QUERIES_TABLE do |rows|
        rows << attributes
      end
    end

    def validate!
      raise NotValid.new('Name cannot be blank!') if attributes[:name].blank?
    end
  end
end

class LoghouseQuery
  QUERIES_TABLE = ENV.fetch('CLICKHOUSE_QUERIES_TABLE') { 'queries' }

  module Storable
    class NotValid < StandardError; end
    class NotFound < StandardError; end

    extend ActiveSupport::Concern

    module ClassMethods
      def create_table!(force = false)
        if Clickhouse.connection.exists_table(QUERIES_TABLE)
          return unless force

          Clickhouse.connection.drop_table(QUERIES_TABLE)
        end

        Clickhouse.connection.create_table(QUERIES_TABLE) do |t|
          t.fixed_string :id, 36
          t.string       :name
          t.string       :query
          t.string       :time_from
          t.string       :time_to
          t.uint8        :follow
          t.engine       "TinyLog"
        end
      end

      def all
        Clickhouse.connection.select_rows(select: '*', from: QUERIES_TABLE).map { |r| build_from_row r }
      end

      def find(id)
        if (row = Clickhouse.connection.select_row(select: '*', from: QUERIES_TABLE, where: { id: id }))
          build_from_row row
        end
      end

      def find!(id)
        find(id) || raise(NotFound.new("Record with id='#{id} not found!'"))
      end

      protected

      def build_from_row(row)
        new id: row[0], name: row[1], query: row[2], time_from: row[3], time_to: row[4], follow: row[5]
      end
    end

    def save!
      validate!

      return false unless self.class.find(id).blank?

      all_attrs = {
        id:        nil,
        name:      nil,
        query:     nil,
        time_from: nil,
        time_to:   nil,
        follow:    0
      } # Trick for all-attributes-hash in correct order in insert

      Clickhouse.connection.insert_rows QUERIES_TABLE do |rows|
        rows << all_attrs.merge(attributes)
      end
    end

    def validate!
      raise NotValid.new('Name cannot be blank!') if attributes[:name].blank?
    end
  end
end

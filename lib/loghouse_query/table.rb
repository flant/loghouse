class LoghouseQuery
  QUERIES_TABLE = ENV.fetch('CLICKHOUSE_QUERIES_TABLE') { 'queries' }

  class << self
    attr_accessor :table_version
  end

  self.table_version = 1

  module Table
    extend ActiveSupport::Concern

    module ClassMethods
      def table_name(version = table_version)
        if version.zero?
          QUERIES_TABLE
        else
          [QUERIES_TABLE, "v#{version}"].join('_')
        end
      end

      def columns(version = table_version)
        case version
        when 0
          {
            id:         nil,
            name:       nil,
            namespaces: [],
            query:      nil,
            time_from:  'now-15m',
            time_to:    'now',
            position:   nil
          }
        when 1
          {
            id:         nil,
            name:       nil,
            namespaces: [],
            query:      nil,
            position:   nil
          }
        end.freeze # Trick for all-attributes-hash in correct order in insert
      end

      def table_exists?(version: table_version)
        ::Clickhouse.connection.exists_table(table_name(version))
      end

      def create_table_with_migration!
        return if table_exists?

        (0..(table_version-1)).each do |v|
          migrate_table_from_version(v) if ::Clickhouse.connection.exists_table(table_name(v))
        end

        create_table!
      end

      def create_table!(force: false, version: table_version)
        if table_exists?(version: version)
          return unless force

          drop_table!(version: version)
        end

        ::Clickhouse.connection.create_table(table_name(version)) do |t|
          case version
          when 0
            t.fixed_string :id, 36
            t.string       :name
            t.array        :namespaces, 'String'
            t.string       :query
            t.string       :time_from
            t.string       :time_to
            t.uint8        :position
            t.engine       "TinyLog"
          when 1
            t.fixed_string :id, 36
            t.string       :name
            t.array        :namespaces, 'String'
            t.string       :query
            t.uint8        :position
            t.engine       "TinyLog"
          end
        end
      end

      def drop_table!(version: table_version)
        ::Clickhouse.connection.drop_table(table_name(version))
      end

      def migrate_table_from_version(version)
        return if version == table_version

        cur_version = table_version
        case version
        when 0
          self.table_version = version
          data = all
          data.each do |q|
            q.attributes.delete(:time_from)
            q.attributes.delete(:time_to)
          end
          self.table_version = version + 1
          create_table!
          data.each(&:save!)

          drop_table!(version: version)
        end
        self.table_version = cur_version
      end
    end
  end
end

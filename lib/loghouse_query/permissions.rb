class LoghouseQuery
  PERMISSONS_FILE_PATH = ENV.fetch('PERIMISSONS_FILE_PATH') { 'config/permissions.yml' }

  module Permissions
    extend ActiveSupport::Concern

    def permissions_config
      @permissions_config ||= YAML.load_file(PERMISSONS_FILE_PATH)
    end

    def to_clickhouse_permissions
      namespaces = permissions_config[Loghouse.current_user]
      raise "no user permissions configured for user '#{Loghouse.current_user}'" if namespaces.blank?

      permissions_query = namespaces.map { |ns| "namespace=#{ns}" }.join(' OR ')
      Clickhouse::Query.new(parser.parse(permissions_query)[:query]).to_s
    end

    def to_clickhouse_where
      "(#{[super, to_clickhouse_permissions].join(') AND (')})"
    end
  end
end

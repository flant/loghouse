class LoghouseQuery
  module Permissions
    extend ActiveSupport::Concern

    def to_clickhouse_permissions
      permissions = User.current.permissions

      permissions_query = permissions.map { |p| "namespace=~'#{p}'" }.join(' OR ')
      Clickhouse::Query.new(parser.parse(permissions_query)[:query]).to_s
    end

    def to_clickhouse_where(from = nil, to = nil)
      "(#{[super, to_clickhouse_permissions].join(') AND (')})"
    end
  end
end

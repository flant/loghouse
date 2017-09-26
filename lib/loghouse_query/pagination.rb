class LoghouseQuery
  module Pagination
    attr_reader :page, :per_page

    def page
      @page || 1
    end
    alias :current_page :page

    def per_page
      @per_page || 10
    end
    alias :limit :per_page

    def total_entries
      @total_entries ||= Clickhouse.connection.count(from: LOGS_TABLE, where: to_clickhouse_where)
    end

    def total_pages
      follow? ? 1 : (total_entries / per_page.to_f).ceil
    end

    def paginate(page: nil, per_page: nil)
      @page     = page.to_i if page.present?
      @per_page = per_page.to_i if per_page.present?
      self
    end

    def offset
      if follow?
        (total_entries > per_page) ? (total_entries - per_page) : 0
      else
        (page - 1) * per_page
      end
    end
  end
end

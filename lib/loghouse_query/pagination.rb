class LoghouseQuery
  module Pagination
    attr_reader :per_page, :older_than, :newer_than

    def per_page
      @per_page || 50
    end
    alias :limit :per_page

    def paginate(newer_than:, older_than: nil, per_page: nil)
      @newer_than = newer_than if newer_than.present?
      @older_than = older_than if older_than.present? && !@newer_than
      @per_page = per_page.to_i if per_page.present?
      self
    end

    def to_clickhouse_pagination_where
      if newer_than
        time_comparation newer_than, '>'
      elsif older_than
        time_comparation older_than, '<'
      end
    end

    private

    def time_comparation(time, comparation)
      timestamp, nsec = time.split('.')

      [
        [
          [TIMESTAMP_ATTRIBUTE, to_clickhouse_time(timestamp)].join(' = '),
          [NSEC_ATTRIBUTE, nsec].join(" #{comparation} ")
        ].join(' AND '),
        [TIMESTAMP_ATTRIBUTE, to_clickhouse_time(timestamp)].join(" #{comparation} "),
      ].join(' OR ')
    end
  end
end

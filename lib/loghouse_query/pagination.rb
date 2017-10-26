class LoghouseQuery
  module Pagination
    DEFAULT_PER_PAGE = 250
    attr_reader :per_page, :older_than, :newer_than

    alias :limit :per_page

    def paginate(newer_than: nil, older_than: nil, per_page: nil)
      @newer_than  = newer_than if newer_than.present?
      @older_than  = older_than if older_than.present? && !@newer_than
      @per_page    = per_page.to_i if per_page.present?

      @per_page ||= DEFAULT_PER_PAGE
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
          [LogsTables::TIMESTAMP_ATTRIBUTE, to_clickhouse_time(timestamp)].join(' = '),
          [LogsTables::NSEC_ATTRIBUTE, nsec].join(" #{comparation} ")
        ].join(' AND '),
        [LogsTables::TIMESTAMP_ATTRIBUTE, to_clickhouse_time(timestamp)].join(" #{comparation} "),
      ].join(' OR ')
    end
  end
end

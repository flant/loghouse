class LoghouseQuery
  module Pagination
    DEFAULT_PER_PAGE = 250
    attr_reader :per_page, :older_than, :newer_than

    alias :limit :per_page

    def paginate(newer_than: nil, older_than: nil, per_page: nil)
      @newer_than = Time.zone.parse(newer_than).utc if newer_than.present?
      @older_than = Time.zone.parse(older_than).utc if older_than.present? && !@newer_than
      @per_page   = per_page.to_i if per_page.present?

      @per_page ||= DEFAULT_PER_PAGE
      self
    end

    def parsed_seek_to
      (@newer_than.present? || @oler_than.present?) ? nil : super
    end

    def parsed_time_from
      s = super

      return s if newer_than.blank?

      [s, newer_than].compact.max
    end

    def parsed_time_to
      s = super

      return s if older_than.blank?

      [s, older_than].compact.min
    end
  end
end

class LoghouseQueryTimeP < Parslet::Parser
  include ParsletExtensions

  rule(:now) { str('now') }
  rule(:from_now) do
    now >>
    str('-') >>
    match['\d+'].repeat(1).as(:count) >>
    match['mdhwMy'].as(:type)
  end

  rule(:time) { from_now.as(:from_now) | now.as(:now) }

  root :time

  def parse_time(str)
    begin
      parsed = parse(str)

      time =  if parsed[:now]
                Time.zone.now
              else
                type =  case parsed[:from_now][:type]
                        when 'm'
                          'minutes'
                        when 'h'
                          'hours'
                        when 'd'
                          'days'
                        when 'w'
                          'weeks'
                        when 'M'
                          'months'
                        when 'y'
                          'years'
                        end
                parsed[:from_now][:count].to_i.send(type).ago
              end

    rescue Parslet::ParseFailed => e
      time = Time.zone.parse(str)
      raise LoghouseQuery::BadTimeFormat.new("#{str}: #{e}") if time.blank?
    end
    time
  end
end

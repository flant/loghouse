module ParsletExtensions
  extend ActiveSupport::Concern

  included do
    rule(:space) { match('\s').repeat(1) }
    rule(:space?) { space.maybe }
  end

  def stri(str)
    key_chars = str.split(//)
    key_chars.
      collect! { |char| match["#{char.upcase}#{char.downcase}"] }.
      reduce(:>>)
  end

  def spaced(atom)
    space? >> atom >> space?
  end

  def parenthesed(atom)
    (str('(') >> atom >> str(')')) | atom
  end
end

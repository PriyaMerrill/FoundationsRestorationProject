# Full-text search for a kind of record, using PostgreSQL.
#
#   include Searchable
#   searchable against: { title: "A", summary: "B" }, associated: { people: :name }
#
#   Event.matching("Liberty Jail")   # best matches first
#
# Weights run from "A" (matters most, such as a title) to "D". A search
# finds records containing every word, in any order, and understands
# word endings ("translating" finds "translation").
module Searchable
  extend ActiveSupport::Concern

  included do
    include PgSearch::Model
  end

  class_methods do
    def searchable(against:, associated: {})
      @pg_search_label_column = against.keys.first
      pg_search_scope :search_text, against: against, associated_against: associated,
        using: { tsearch: { prefix: true, dictionary: "english" } }
    end

    # Best matches first. A record whose name is exactly what was typed
    # comes before everything else ("Joseph Smith" before "Joseph Smith Sr.").
    def matching(query)
      query = Searchable.normalize(query)
      return none if query.blank?

      results = search_text(query)
      label = pg_search_label_column
      exact = sanitize_sql_array([ "LOWER(#{quoted_table_name}.#{connection.quote_column_name(label)}) = ? DESC", query.downcase ])
      results.reorder(Arel.sql(exact), *results.order_values)
    end

    # The column holding a record's name: the first one it is searchable against.
    def pg_search_label_column
      @pg_search_label_column
    end
  end

  # "D&C 76" and "section 76" are how people write "Doctrine and Covenants 76".
  def self.normalize(query)
    query.to_s.strip
      .gsub(/\bd\s*(?:&|and)\s*c\b\.?/i, "Doctrine and Covenants")
      .gsub(/\bsection\s+(?=\d)/i, "Doctrine and Covenants ")
      .squish
  end
end

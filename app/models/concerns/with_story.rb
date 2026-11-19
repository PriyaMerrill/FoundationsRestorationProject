# Gives a record a longer write-up in titled sections, shown under its summary.
#
#   person.story_sections  # => [ [ "Early life", [ "First paragraph", "Second paragraph" ] ], ... ]
module WithStory
  extend ActiveSupport::Concern

  def story_sections
    Array(story).filter_map do |section|
      paragraphs = section["body"].to_s.split(/\n\s*\n/).map(&:squish).compact_blank
      [ section["heading"], paragraphs ] if section["heading"].present? && paragraphs.any?
    end
  end

  # Everything in the story as one string, for searching.
  def story_text
    story_sections.flat_map(&:last).join(" ")
  end
end

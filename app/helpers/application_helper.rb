module ApplicationHelper
  SITE_NAME = "Foundations of the Restoration".freeze

  # The links shown in the header, mobile menu and footer.
  def main_navigation
    {
      "Road Trip" => road_trip_path,
      "Timeline" => timeline_path,
      "By the Numbers" => numbers_path,
      "Trivia" => trivia_path,
      "Explore" => explore_path,
      "Sources" => sources_path
    }
  end

  # Browser tab title: "Kirtland · Foundations of the Restoration".
  def page_title
    [ content_for(:title).presence, SITE_NAME ].compact.join(" · ")
  end

  # What to call a record in a link or heading.
  def record_label(record)
    case record
    when Revelation then record.reference || record.title
    when Event then record.title
    else record.name
    end
  end

  # The word shown beside a record so visitors know what kind of thing it is.
  def record_type_label(record)
    record.class.model_name.human
  end

  # Badge colour for each kind of record.
  def record_tone(record)
    { "Event" => "forest", "Place" => "brown", "Person" => "slate", "Revelation" => "gold" }.fetch(record.class.name, "slate")
  end

  # "scripture_translation" -> "Scripture translation", "new_york" -> "New York"
  def category_label(value)
    value.to_s.humanize
  end

  def period_label(value)
    value.to_s.titleize
  end
end

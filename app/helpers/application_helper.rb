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
    safe_join([ content_for(:title).presence, SITE_NAME ].compact, " · ")
  end

  DEFAULT_DESCRIPTION = "Explore the people, places, revelations and events of early Latter-day Saint history through maps, timelines, charts and trivia.".freeze

  # The sentence search engines and link previews show for a page.
  def page_description
    content_for(:description).presence || DEFAULT_DESCRIPTION
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

  # The four navigation cards on the home page.
  def home_experiences
    [
      { title: "Restoration Road Trip", path: road_trip_path, action: "Start the road trip",
        text: "Travel the map from Palmyra to the Salt Lake Valley and see what happened at each stop.",
        icon: "M12 21s-7-6.2-7-11.5a7 7 0 0 1 14 0C19 14.800 12 21 12 21z M12 12a2.500 2.500 0 1 0 0-5 2.500 2.500 0 0 0 0 5z" },
      { title: "Interactive Timeline", path: timeline_path, action: "Explore the timeline",
        text: "Move through the years 1820 to 1847 and open any event for the full story.",
        icon: "M3 12h18 M7 8v8 M12 6v12 M17 8v8" },
      { title: "Restoration by the Numbers", path: numbers_path, action: "See the charts",
        text: "Charts of membership growth, revelations by place and year, and the spread of the Church.",
        icon: "M4 20V10 M10 20V4 M16 20v-7 M3 20h18" },
      { title: "Restoration Trivia", path: trivia_path, action: "Play trivia",
        text: "Test what you know with quizzes built from the same historical records.",
        icon: "M9.500 9a2.500 2.500 0 1 1 3.500 2.300c-.700.400-1 1-1 1.700V14 M12 17.500h.010 M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20z" }
    ]
  end

  # True once a hero photograph has been added at app/assets/images/hero.jpg.
  def hero_image?
    Rails.application.assets.load_path.find("hero.jpg").present?
  end

  # What the map needs to know about each place, as JSON for the map controller.
  def map_places_json(places)
    previous = nil

    places.map do |place|
      # Straight-line miles from the stop before this one on the road trip.
      leg = { miles: previous.miles_to(place), from: previous.name } if place.trail_order && previous
      previous = place if place.trail_order

      { slug: place.slug, name: place.name, lat: place.latitude.to_f, lng: place.longitude.to_f,
        kinds: place.kinds, stop: place.trail_order, url: place_path(place),
        facts: [ place.state, place.years ].compact_blank.join(" · "), leg: leg }
    end.to_json
  end

  # Turns report points into JSON for the chart controller.
  def chart_points_json(points)
    points.map do |point|
      { label: point.label, value: point.value, detail: point.detail,
        records: point.records.map { |record| { label: record_label(record), type: record_type_label(record), url: polymorphic_path(record) } } }
    end.to_json
  end

  # The line of facts shown under a record in search results.
  def record_facts(record)
    facts =
      case record
      when Event then [ record.display_dates, record.place&.name ]
      when Revelation then [ record.display_date, record.place&.name ]
      when Place then [ record.state, record.years ]
      when Person then [ [ record.birth_date&.year, record.death_date&.year ].compact.join("–"), record.roles ]
      end
    facts.compact_blank.join(" · ")
  end

  # A sentence or two describing a record, for search results.
  def record_excerpt(record)
    text = record.is_a?(Person) ? record.biography : record.summary
    truncate(text.to_s, length: 170, separator: " ")
  end

  # An event's date split for the timeline: a small line and a large year.
  # Only what is known about the date is shown.
  #   exact:       [ "March 27", 1836 ]            month: [ "June", 1828 ]
  #   year:        [ "Year", 1820 ]                approximate: [ "About", 1829 ]
  #   with an end: [ "Dec 1 – Apr 6, 1839", 1838 ]
  def timeline_date_parts(event)
    date = event.start_date

    small =
      case event.date_precision
      when "exact"
        if event.end_date
          finish = event.end_date
          "#{date.strftime("%b %-d")} – #{finish.strftime(finish.year == date.year ? "%b %-d" : "%b %-d, %Y")}"
        else
          date.strftime("%B %-d")
        end
      when "month" then date.strftime("%B")
      when "year" then "Year"
      else "About"
      end

    [ small, date.year ]
  end
end

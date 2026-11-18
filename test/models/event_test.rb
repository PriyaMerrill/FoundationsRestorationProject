require "test_helper"

class EventTest < ActiveSupport::TestCase
  test "requires a title, date, category and period" do
    event = Event.new
    assert_not event.valid?
    assert event.errors[:title].any?
    assert event.errors[:start_date].any?
    assert event.errors[:category].any?
    assert event.errors[:period].any?
  end

  test "rejects an unknown category" do
    assert_not Event.new(title: "X", start_date: Date.new(1830, 4, 6), category: "sports", period: "new_york").valid?
  end

  test "builds its slug from the title" do
    assert_equal "kirtland-temple-dedication", create_event.slug
  end

  test "reaches its place, people, revelations and sources" do
    kirtland = create_place
    joseph = create_person
    section = create_revelation
    papers = create_source
    event = create_event(place: kirtland)
    event.event_participants.create!(person: joseph, role: "Offered the dedicatory prayer")
    event.revelations << section
    event.citations.create!(source: papers, note: "Journal, March 27, 1836")

    assert_equal kirtland, event.place
    assert_equal [ joseph ], event.people.to_a
    assert_equal [ section ], event.revelations.to_a
    assert_equal [ papers ], event.sources.to_a
  end

  test "filters by category and period" do
    dedication = create_event
    create_event("Martyrdom", start_date: Date.new(1844, 6, 27), category: "persecution", period: "nauvoo")

    assert_equal [ dedication ], Event.category_temples.to_a
    assert_equal [ dedication ], Event.period_ohio.to_a
  end

  test "chronological puts the earliest first" do
    later = create_event
    earlier = create_event("First Vision", start_date: Date.new(1820, 3, 1), date_precision: "approximate", category: "revelations", period: "new_york")
    assert_equal [ earlier, later ], Event.chronological.to_a
  end

  test "on this day only matches exact dates" do
    dedication = create_event
    create_event("Vague event", start_date: Date.new(1833, 3, 27), date_precision: "year")
    assert_equal [ dedication ], Event.on_this_day(Date.new(2026, 3, 27)).to_a
  end

  test "display date respects how exactly the date is known" do
    date = Date.new(1836, 3, 27)
    assert_equal "March 27, 1836", Event.new(start_date: date, date_precision: "exact").display_date
    assert_equal "March 1836", Event.new(start_date: date, date_precision: "month").display_date
    assert_equal "1836", Event.new(start_date: date, date_precision: "year").display_date
    assert_equal "c. 1836", Event.new(start_date: date, date_precision: "approximate").display_date
    assert_nil Event.new.display_date
  end

  test "display dates shows a range when there is an end date" do
    jail = Event.new(start_date: Date.new(1838, 12, 1), end_date: Date.new(1839, 4, 6))
    assert_equal "December 1, 1838 – April 6, 1839", jail.display_dates
    assert_equal "March 27, 1836", Event.new(start_date: Date.new(1836, 3, 27)).display_dates
  end
end

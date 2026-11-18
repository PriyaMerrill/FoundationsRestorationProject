require "test_helper"

class HomePageTest < ActionDispatch::IntegrationTest
  test "shows the hero and both calls to action" do
    get root_path

    assert_response :success
    assert_select "h1", text: "Explore the Restoration"
    assert_select "a[href=?]", timeline_path, text: "Explore the Timeline"
    assert_select "a[href=?]", road_trip_path, text: "Start the Road Trip"
  end

  test "shows the four navigation cards" do
    get root_path

    assert_select "#experiences-heading ~ ul a.card", count: 4
    [ road_trip_path, timeline_path, numbers_path, trivia_path ].each do |path|
      assert_select "a.card[href=?]", path
    end
  end

  test "loads with an empty database" do
    get root_path
    assert_response :success
    assert_select "#featured-heading", count: 0
  end

  test "shows an event that happened on this day" do
    create_event
    create_event("First Vision", start_date: Date.new(1820, 3, 1), date_precision: "year", category: "revelations", period: "new_york")

    travel_to Time.zone.local(2026, 3, 27, 12) do
      get root_path
    end

    assert_select "a[href=?]", event_path("kirtland-temple-dedication") do
      assert_select "p", text: "On this day in Church history"
    end
  end

  test "falls back to a featured event on other days" do
    create_event

    travel_to Time.zone.local(2026, 11, 18, 12) do
      get root_path
    end

    assert_select "a[href=?]", event_path("kirtland-temple-dedication") do
      assert_select "p", text: "Featured event"
    end
  end

  test "features a person and a revelation and counts the records" do
    create_person
    create_revelation(76, received_on: Date.new(1832, 2, 16))

    get root_path

    assert_select "a[href=?]", person_path("joseph-smith")
    assert_select "a[href=?]", revelation_path("doctrine-and-covenants-76"), text: /D&C 76/
    assert_select "dl dt", text: "people"
  end
end

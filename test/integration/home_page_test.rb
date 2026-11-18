require "test_helper"

class HomePageTest < ActionDispatch::IntegrationTest
  test "shows a compact hero with no buttons" do
    get root_path

    assert_response :success
    assert_select "h1", text: "Explore the Restoration"
    assert_select "section:first-of-type a", count: 0
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

  test "features an event as a calendar page, a person as a portrait and a revelation as a page" do
    create_event(place: create_place, summary: "The first temple was dedicated.")
    create_person(clues: [ "I was born in Vermont in 1805." ], roles: "Prophet")
    create_revelation(76, received_on: Date.new(1832, 2, 16), summary: "A vision of the kingdoms of glory.")

    get root_path

    assert_select "article a[href=?]", timeline_path(event: "kirtland-temple-dedication"), text: "Kirtland Temple dedication"
    assert_select "article p", text: "March"
    assert_select "article p", text: "27"
    assert_select "article p", text: "1836"
    assert_select "article span", text: "Ohio period"

    assert_select "article a[href=?]", person_path("joseph-smith"), text: "Joseph Smith"
    assert_select "article blockquote", text: /I was born in Vermont in 1805/
    assert_select "article span", text: "JS"

    assert_select "article a[href=?]", revelation_path("doctrine-and-covenants-76"), text: /Section\s+76/
    assert_select "article p", text: "A vision of the kingdoms of glory."
  end

  test "an event known only to the year shows the year, not a made-up day" do
    create_event("The First Vision", start_date: Date.new(1820, 3, 1), date_precision: "year", category: "revelations", period: "new_york")

    get root_path

    assert_select "article p", text: "The year"
    assert_select "article p", text: "1820"
    assert_select "article p", text: "March", count: 0
  end

  test "shows nothing about this day in history" do
    create_event
    travel_to Time.zone.local(2026, 3, 27, 12) do
      get root_path
    end
    assert_select "body", text: /On this day/, count: 0
  end

  test "no longer shows record counts" do
    create_event
    get root_path
    assert_select "dl", count: 0
  end
end

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

  test "shows a banner for an event that happened on this day" do
    create_event
    create_event("First Vision", start_date: Date.new(1820, 3, 1), date_precision: "year", category: "revelations", period: "new_york")

    travel_to Time.zone.local(2026, 3, 27, 12) do
      get root_path
    end

    assert_select "section[aria-label='On this day in Church history'] a[href=?]", event_path("kirtland-temple-dedication"),
      text: /March 27, 1836: Kirtland Temple dedication/
  end

  test "shows no banner on other days" do
    create_event

    travel_to Time.zone.local(2026, 11, 18, 12) do
      get root_path
    end

    assert_select "section[aria-label='On this day in Church history']", count: 0
  end

  test "features a place as a map, a person as a portrait and a revelation as a page" do
    create_place(state: "Ohio", latitude: 41.6253, longitude: -81.3622, trail_order: 4, summary: "Site of the first temple.")
    create_place("Unmapped")
    create_person(clues: [ "I was born in Vermont in 1805." ], roles: "Prophet")
    create_revelation(76, received_on: Date.new(1832, 2, 16), summary: "A vision of the kingdoms of glory.")

    get root_path

    assert_select "article a[href=?]", road_trip_path(place: "kirtland"), text: "Kirtland"
    assert_select "[data-controller=minimap][data-minimap-lat-value='41.6253'][data-minimap-lng-value='-81.3622']"
    assert_select "article span", text: "Stop 4 on the road trip"

    assert_select "article a[href=?]", person_path("joseph-smith"), text: "Joseph Smith"
    assert_select "article blockquote", text: /I was born in Vermont in 1805/
    assert_select "article span", text: "JS"

    assert_select "article a[href=?]", revelation_path("doctrine-and-covenants-76"), text: /Section\s+76/
    assert_select "article p", text: "A vision of the kingdoms of glory."
  end

  test "no longer shows record counts" do
    create_event
    get root_path
    assert_select "dl", count: 0
  end
end

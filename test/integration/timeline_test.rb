require "test_helper"

class TimelineTest < ActionDispatch::IntegrationTest
  setup do
    @liberty = create_place("Liberty")
    @joseph = create_person
    @sections = [ 121, 122, 123 ].map { |number| create_revelation(number) }
    @jail = create_event("Imprisonment in Liberty Jail", slug: "liberty-jail", start_date: Date.new(1838, 12, 1),
      end_date: Date.new(1839, 4, 6), category: "persecution", period: "missouri", place: @liberty)
    @jail.people << @joseph
    @jail.revelations = @sections

    @dedication = create_event(place: create_place)
    @vision = create_event("The First Vision", start_date: Date.new(1820, 3, 1), date_precision: "year",
      category: "revelations", period: "new_york")
  end

  test "lists events in order, grouped by period" do
    get timeline_path

    assert_response :success
    assert_select "section h2", count: 3
    assert_equal [ "New York", "Ohio", "Missouri" ], css_select("section h2").map(&:text)
    assert_select "nav[aria-label='Jump to a period'] a[href='#period-ohio']"
    assert_select "p[role=status]", text: /3 events/
  end

  test "event cards open in the panel" do
    get timeline_path
    assert_select "a[href=?][data-turbo-frame=panel]", event_path(@jail), text: /December 1, 1838 – April 6, 1839/
    assert_select "turbo-frame#panel"
  end

  test "filters by category" do
    get timeline_path(category: "persecution")

    assert_select "ol a.card", count: 1
    assert_select "a[aria-current=true]", text: "Persecution"
    assert_select "a.card", text: /Liberty Jail/
  end

  test "ignores an unknown category" do
    get timeline_path(category: "sports")
    assert_select "ol a.card", count: 3
  end

  test "searches by person, place, event and revelation" do
    { "Joseph" => 1, "liberty" => 1, "vision" => 1, "D&C 122" => 1, "Kirtland" => 1, "zzz" => 0 }.each do |query, count|
      get timeline_path(q: query)
      assert_select "ol a.card", { count: count }, "searching for #{query}"
    end
  end

  test "search and category combine" do
    get timeline_path(q: "Joseph", category: "temples")
    assert_select "ol a.card", count: 0
    assert_select "p", text: "No events match."
  end

  test "a deep link opens the event in the panel" do
    get timeline_path(event: "liberty-jail")
    assert_select "turbo-frame#panel[src=?]", event_path(@jail)
  end

  test "an unknown deep link is ignored" do
    get timeline_path(event: "nope")
    assert_response :success
    assert_select "turbo-frame#panel[src]", count: 0
  end

  test "the panel shows Liberty Jail with its people, scriptures and a map link" do
    get event_path(@jail), headers: { "Turbo-Frame" => "panel" }

    assert_response :success
    assert_select "header", count: 0
    assert_select "turbo-frame#panel article[data-panel-key=liberty-jail]" do
      assert_select "h2", text: "Imprisonment in Liberty Jail"
      assert_select "a[href=?]", person_path(@joseph)
      @sections.each { |section| assert_select "a[href=?]", revelation_path(section) }
      assert_select "a[href=?]", road_trip_path(place: "liberty"), text: /on the map/
      assert_select "a[href=?]", event_path(@jail), text: "Open the full page"
    end
  end
end

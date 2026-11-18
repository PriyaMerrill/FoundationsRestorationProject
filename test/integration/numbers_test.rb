require "test_helper"

class NumbersTest < ActionDispatch::IntegrationTest
  setup do
    @kirtland = create_place(state: "Ohio", latitude: 41.6, longitude: -81.3, start_year: 1831, end_year: 1838)
    @section = create_revelation(110, received_on: Date.new(1836, 4, 3), place: @kirtland)
    @dedication = create_event(place: @kirtland)
    MembershipEstimate.create!(year: 1836, members: 13_293, source: create_source("Deseret News Church Almanac", slug: "church-almanac"))
  end

  test "shows every chart with its data, table and notes" do
    get numbers_path

    assert_response :success
    assert_select "[data-controller=chart]", count: 8
    [ "Church membership growth", "Revelations by location", "Revelations over time", "Events over time" ].each do |title|
      assert_select "h2", text: title
    end
    assert_select "h3", text: "Temple events"
    assert_select "strong", text: "Caveat:", minimum: 4
    assert_select "p", text: /Deseret News Church Almanac/
  end

  test "gives each chart its points with links back to the records" do
    get numbers_path

    chart = css_select("[data-controller=chart]").find { |node| node.at("h2")&.text == "Revelations by location" }
    points = JSON.parse(chart["data-chart-points-value"])

    assert_equal "Kirtland", points.first["label"]
    assert_equal 1, points.first["value"]
    assert_equal [ place_path(@kirtland), revelation_path(@section) ], points.first["records"].map { |record| record["url"] }
  end

  test "the table repeats the figures and links to the records" do
    get numbers_path

    assert_select "details table td", text: "13,293"
    assert_select "details table a[href=?]", revelation_path(@section), text: "D&C 110"
    assert_select "details table a[href=?]", event_path(@dedication)
  end

  test "filters narrow the charts and can be cleared" do
    get numbers_path(from: 1840, period: "ohio")

    assert_select "input[name=from][value='1840']"
    assert_select "select[name=period] option[selected][value=ohio]"
    assert_select "a[href=?]", numbers_path, text: "Clear filters"
    assert_select "p", text: "Nothing matches the current filters.", minimum: 4
  end

  test "sets up the expansion map" do
    get numbers_path

    places = JSON.parse(css_select("[data-controller=expansion]").first["data-expansion-places-value"])
    assert_equal [ { "name" => "Kirtland", "lat" => 41.6, "lng" => -81.3, "start" => 1831, "end" => 1838, "url" => "/places/kirtland" } ], places
    assert_select "input[type=range][min='1830'][max='1850']"
  end
end

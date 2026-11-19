require "test_helper"

class NumbersTest < ActionDispatch::IntegrationTest
  setup do
    @kirtland = create_place(state: "Ohio", latitude: 41.6, longitude: -81.3, start_year: 1831, end_year: 1838)
    @section = create_revelation(110, received_on: Date.new(1836, 4, 3), place: @kirtland)
    almanac = create_source("Deseret News Church Almanac", slug: "church-almanac")
    MembershipEstimate.create!(year: 1836, members: 13_293, source: almanac)
    MembershipEstimate.create!(year: 1837, members: 16_282, source: almanac)
  end

  def chart(title)
    css_select("[data-controller=chart]").find { |node| node.at("h2")&.text == title }
  end

  test "shows only charts that count something complete" do
    get numbers_path

    assert_response :success
    assert_equal [ "Church membership growth", "Members gained each year", "Doctrine and Covenants sections by year",
      "Doctrine and Covenants sections by place" ], css_select("[data-controller=chart] h2").map(&:text)
    assert_select "h2", text: /Revelations by location|Revelations over time|Events over time|Comparing the periods/, count: 0
    assert_select "p", text: /all 138 sections of the Doctrine and Covenants/
    assert_select "p", text: /Deseret News Church Almanac/
    assert_select "p", text: /D&C 138, received in 1918/
  end

  test "shows headline figures" do
    get numbers_path

    assert_select "dl .stat-tile", count: 5
    assert_select "dl dd", text: "13,293"
    assert_select "dl dt", text: "members in 1836"
    assert_select "dl dd", text: "137"
  end

  test "filters by years only" do
    get numbers_path

    assert_select "input[name=from]"
    assert_select "input[name=to]"
    assert_select "select[name=category]", count: 0
    assert_select "select[name=period]", count: 0
    assert_select "select[name=place]", count: 0
  end

  test "a year range narrows the charts and can be cleared" do
    get numbers_path(from: 1838, to: 1839)

    assert_select "input[name=from][value='1838']"
    assert_select "a[href=?]", numbers_path, text: "Show all years"
    assert_equal %w[1838 1839], JSON.parse(chart("Doctrine and Covenants sections by year")["data-chart-points-value"]).map { |point| point["label"] }
    assert_select "p", text: "Nothing falls in the years chosen.", count: 2
  end

  test "the sections chart is stacked by state, with a key" do
    get numbers_path

    node = chart("Doctrine and Covenants sections by year")
    series = JSON.parse(node["data-chart-series-value"])

    assert_equal [ "New York", "Pennsylvania", "Ohio", "Missouri", "Illinois", "Elsewhere" ], series.map { |part| part["name"] }
    assert_equal "#238a63", series.find { |part| part["name"] == "Ohio" }["color"]
    assert_equal [ "New York", "Pennsylvania", "Ohio", "Missouri", "Illinois", "Elsewhere" ], node.css("ul[aria-label=Key] li").map { |item| item.text.strip }
  end

  test "bars link to this site's page for a section, or to the official edition" do
    get numbers_path

    points = JSON.parse(chart("Doctrine and Covenants sections by place")["data-chart-points-value"])
    kirtland = points.first

    assert_equal "Kirtland, Ohio", kirtland["label"]
    assert_equal 46, kirtland["value"]
    assert_equal revelation_path(@section), kirtland["records"].find { |record| record["label"] == "D&C 110" }["url"]
    assert_match "churchofjesuschrist.org", kirtland["records"].find { |record| record["label"] == "D&C 42" }["url"]
  end

  test "the table repeats the figures and links to the records" do
    get numbers_path

    assert_select "details table td", text: "13,293"
    assert_select "details table td", text: "2,989", count: 1 # members gained in 1837
    assert_select "details table a[href=?]", revelation_path(@section), text: "D&C 110"
  end

  test "sets up the expansion map with a reset button" do
    get numbers_path

    places = JSON.parse(css_select("[data-controller=expansion]").first["data-expansion-places-value"])
    assert_equal [ { "name" => "Kirtland", "lat" => 41.6, "lng" => -81.3, "start" => 1831, "end" => 1838, "url" => "/places/kirtland" } ], places
    assert_select "input[type=range][min='1830'][max='1850']"
    assert_select "button[data-action='expansion#reset']", text: "Reset"
  end
end

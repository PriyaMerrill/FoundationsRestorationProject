require "test_helper"

class RoadTripTest < ActionDispatch::IntegrationTest
  setup do
    @palmyra = create_place("Palmyra", latitude: 43.04, longitude: -77.24, kinds: %w[revelation_site], trail_order: 1, state: "New York")
    @kirtland = create_place("Kirtland", latitude: 41.6253, longitude: -81.3622, kinds: %w[temple revelation_site],
      trail_order: 2, state: "Ohio", start_year: 1831, end_year: 1838)
    @hawns_mill = create_place("Hawn's Mill", latitude: 39.668, longitude: -93.838, kinds: %w[landmark])
    create_place("Somewhere unmapped")

    @joseph = create_person
    @section = create_revelation(110, received_on: Date.new(1836, 4, 3), place: @kirtland)
    @arrival = create_event("Joseph Smith arrives in Kirtland", start_date: Date.new(1831, 2, 1), date_precision: "month", category: "migration", place: @kirtland)
    @building = create_event("Construction of the Kirtland Temple begins", start_date: Date.new(1833, 6, 1), date_precision: "year", place: @kirtland)
    @dedication = create_event(place: @kirtland)
    @visions = create_event("Visions in the Kirtland Temple", start_date: Date.new(1836, 4, 3), category: "revelations", place: @kirtland)
    @dedication.people << @joseph
  end

  test "gives the map every place that has coordinates" do
    get road_trip_path

    assert_response :success
    places = JSON.parse(css_select("[data-controller=map]").first["data-map-places-value"])

    assert_equal [ "palmyra", "kirtland", "hawn-s-mill" ], places.map { |place| place["slug"] }
    kirtland = places[1]
    assert_equal({ "slug" => "kirtland", "name" => "Kirtland", "lat" => 41.6253, "lng" => -81.3622,
      "kinds" => %w[temple revelation_site], "stop" => 2, "url" => "/places/kirtland", "facts" => "Ohio · 1831–1838" },
      kirtland.except("leg"))
    assert_equal "Palmyra", kirtland.dig("leg", "from")
    assert_in_delta 235, kirtland.dig("leg", "miles"), 15
    assert_nil places[0]["leg"]
    assert_nil places[2]["leg"]
  end

  test "lists the places with links that open in the panel" do
    get road_trip_path

    assert_select "li[data-map-target=item]", count: 3
    assert_select "li[data-slug=kirtland][data-kinds='temple revelation_site'] a[href=?][data-turbo-frame=panel]", place_path(@kirtland)
    assert_select "li[data-slug=kirtland]", text: /About \d+ miles from Palmyra/
    assert_select "turbo-frame#panel"
  end

  test "offers a filter for each kind of place and the route" do
    get road_trip_path

    assert_select "button[data-map-target=filter]", count: 5
    assert_select "button[data-kind=temple]", text: "Temples"
    assert_select "button[data-kind=revelation_site]", text: "Revelation sites"
    assert_select "button[data-map-target=routeButton][data-action='map#startTrip']", text: "Start the road trip"
  end

  test "a deep link opens the place in the panel and selects it on the map" do
    get road_trip_path(place: "kirtland")

    assert_select "turbo-frame#panel[src=?]", place_path(@kirtland)
    assert_select "[data-controller=map][data-map-selected-value=kirtland]"
  end

  test "an unknown deep link is ignored" do
    get road_trip_path(place: "atlantis")
    assert_response :success
    assert_select "turbo-frame#panel[src]", count: 0
  end

  test "the Kirtland panel shows its four dates and links to D&C 110" do
    get place_path(@kirtland), headers: { "Turbo-Frame" => "panel" }

    assert_response :success
    assert_select "turbo-frame#panel article[data-panel-key=kirtland]" do
      assert_select "h2", text: "Kirtland"
      [ "February 1831", "1833", "March 27, 1836", "April 3, 1836" ].each do |date|
        assert_select "a span", text: date
      end
      assert_select "a[href=?]", timeline_path(event: @dedication.slug)
      assert_select "a[href=?]", revelation_path(@section), text: /D&C 110/
      assert_select "a[href=?]", person_path(@joseph)
      assert_select "button.explore-button[data-controller=visited][data-visited-slug-value=kirtland]", text: /Mark as explored/
    end
  end

  test "measures straight-line distance between places" do
    assert_in_delta 235, @palmyra.miles_to(@kirtland), 15
    assert_equal 0, @kirtland.miles_to(@kirtland)
  end

  test "has a trip bar, hidden until a trip starts, with the controls to travel the route" do
    get road_trip_path

    assert_select "section[data-map-target=trip][hidden]" do
      assert_select "button[data-action='map#previousStop']", text: /Back/
      assert_select "button[data-action='map#nextStop']"
      assert_select "button", text: /explored/i, count: 0 # marking a place explored happens in its panel only
      assert_select "button[data-action='map#readAboutStop']", text: "Read about this place"
      assert_select "button.trip-button-small[data-action='map#endTrip']", text: "Finish the trip"
      assert_select "p", text: /2 stops · about \d+ miles in straight lines/
    end
    assert_select "body", text: /Driving distances/, count: 0
  end

  test "lists each place as a ticket with its stop number" do
    get road_trip_path

    assert_select "li[data-slug=palmyra] a.trip-ticket .trip-ticket-stub", text: /Stop\s+1/
    assert_select "li[data-slug=palmyra]", text: /Where the journey begins/
    assert_select "li[data-slug=kirtland] .trip-ticket-stub", text: /Stop\s+2/
    assert_select "li[data-slug=kirtland] .trip-stamp[hidden]", text: "Explored"
  end
end

require "test_helper"

class PlaceTest < ActiveSupport::TestCase
  test "requires a name" do
    assert_not Place.new.valid?
  end

  test "builds its slug from the name" do
    assert_equal "far-west", create_place("Far West").slug
    assert_equal "far-west", Place.find_by(slug: "far-west").to_param
  end

  test "slugs are unique" do
    create_place("Nauvoo")
    assert_not Place.new(name: "Nauvoo").valid?
  end

  test "can be more than one kind and is found by each" do
    kirtland = create_place(kinds: %w[temple revelation_site])
    create_place("Winter Quarters", kinds: %w[settlement])

    assert_equal [ kirtland ], Place.of_kind("temple").to_a
    assert_equal [ kirtland ], Place.of_kind("revelation_site").to_a
  end

  test "rejects unknown kinds" do
    assert_not Place.new(name: "Somewhere", kinds: %w[castle]).valid?
  end

  test "rejects impossible coordinates" do
    assert_not Place.new(name: "Somewhere", latitude: 120, longitude: 0).valid?
  end

  test "mapped only includes places with coordinates" do
    kirtland = create_place(latitude: 41.625, longitude: -81.362)
    create_place("Unknown")
    assert_equal [ kirtland ], Place.mapped.to_a
  end

  test "has events, revelations and the people involved" do
    kirtland = create_place
    joseph = create_person
    event = create_event(place: kirtland)
    event.people << joseph
    revelation = create_revelation(place: kirtland)

    assert_equal [ event ], kirtland.events.to_a
    assert_equal [ revelation ], kirtland.revelations.to_a
    assert_equal [ joseph ], kirtland.people.to_a
  end

  test "deleting a place keeps its events" do
    kirtland = create_place
    event = create_event(place: kirtland)
    kirtland.destroy
    assert_nil event.reload.place
  end
end

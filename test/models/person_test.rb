require "test_helper"

class PersonTest < ActiveSupport::TestCase
  test "requires a name" do
    assert_not Person.new.valid?
  end

  test "builds its slug from the name" do
    assert_equal "emma-smith", create_person("Emma Smith").slug
  end

  test "has events, revelations and places" do
    joseph = create_person
    kirtland = create_place
    event = create_event(place: kirtland)
    revelation = create_revelation
    event.people << joseph
    revelation.people << joseph

    assert_equal [ event ], joseph.events.to_a
    assert_equal [ revelation ], joseph.revelations.to_a
    assert_equal [ kirtland ], joseph.places.to_a
  end

  test "stores clues as a list" do
    joseph = create_person(clues: [ "Born in Vermont in 1805" ])
    assert_equal [ "Born in Vermont in 1805" ], joseph.reload.clues
  end
end

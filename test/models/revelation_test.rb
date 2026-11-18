require "test_helper"

class RevelationTest < ActiveSupport::TestCase
  test "requires a title" do
    assert_not Revelation.new.valid?
  end

  test "section numbers are unique" do
    create_revelation(76)
    assert_not Revelation.new(section_number: 76, title: "Duplicate").valid?
  end

  test "has a reference and display date" do
    section = create_revelation(76, received_on: Date.new(1832, 2, 16))
    assert_equal "D&C 76", section.reference
    assert_equal "February 16, 1832", section.display_date
  end

  test "reaches its place, people and events" do
    hiram = create_place("Hiram")
    joseph = create_person
    sidney = create_person("Sidney Rigdon")
    section = create_revelation(76, place: hiram)
    section.people << [ joseph, sidney ]
    event = create_event("The Vision", start_date: Date.new(1832, 2, 16), category: "revelations")
    event.revelations << section

    assert_equal hiram, section.place
    assert_equal [ joseph, sidney ].sort, section.people.sort
    assert_equal [ event ], section.events.to_a
  end
end

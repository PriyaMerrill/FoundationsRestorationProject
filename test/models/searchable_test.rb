require "test_helper"

class SearchableTest < ActiveSupport::TestCase
  setup do
    @liberty = create_place("Liberty", state: "Missouri", significance: "Joseph Smith spent the winter in Liberty Jail.")
    @kirtland = create_place("Kirtland", state: "Ohio")
    @joseph = create_person(biography: "He translated the Book of Mormon.")
    @emma = create_person("Emma Smith", roles: "First president of the Relief Society", biography: "A scribe during the Book of Mormon translation.")
    @section = create_revelation(76, summary: "A vision of the kingdoms of glory.", place: @kirtland)
    @jail = create_event("Imprisonment in Liberty Jail", start_date: Date.new(1838, 12, 1), category: "persecution", period: "missouri",
      place: @liberty, summary: "Held through the winter.")
    @jail.people << @joseph
    @dedication = create_event(place: @kirtland, summary: "The first temple was dedicated.")
  end

  test "finds records by their own words" do
    assert_equal [ @emma ], Person.matching("Emma Smith").to_a
    assert_equal [ @jail ], Event.matching("Liberty Jail").to_a
    assert_equal [ @liberty ], Place.matching("Liberty Jail").to_a
  end

  test "needs every word but not in order, and understands word endings" do
    assert_equal [ @emma ], Person.matching("translation Mormon scribe").to_a
    assert_equal [ @joseph, @emma ].sort, Person.matching("translating").sort
    assert_empty Person.matching("Emma Liberty")
  end

  test "matches the start of a word" do
    assert_equal [ @kirtland ], Place.matching("Kirt").to_a
  end

  test "finds events through their people, place and revelations" do
    @dedication.revelations << @section

    assert_equal [ @jail ], Event.matching("Joseph Smith").to_a
    assert_equal [ @dedication ], Event.matching("Kirtland").to_a
    assert_equal [ @dedication ], Event.matching("Doctrine and Covenants 76").to_a
  end

  test "ranks a match in the name above a match in the text" do
    create_person("Lucy Mack Smith", biography: "Mother of Joseph Smith.")
    assert_equal "Joseph Smith", Person.matching("Joseph Smith").first.name
  end

  test "understands the usual ways of writing a section" do
    [ "D&C 76", "d & c 76", "D and C 76", "section 76", "Doctrine and Covenants 76" ].each do |query|
      assert_equal [ @section ], Revelation.matching(query).to_a, "searching for #{query}"
    end
  end

  test "a blank search finds nothing" do
    assert_empty Event.matching("")
    assert_empty Event.matching(nil)
  end

  test "survives punctuation" do
    assert_nothing_raised { Event.matching("jail's (winter) & :*!").to_a }
  end
end

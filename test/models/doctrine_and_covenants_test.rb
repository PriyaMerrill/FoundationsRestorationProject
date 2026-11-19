require "test_helper"

class DoctrineAndCovenantsTest < ActiveSupport::TestCase
  test "lists every section once, in order" do
    sections = DoctrineAndCovenants.sections

    assert_equal (1..138).to_a, sections.map(&:number)
    assert_equal 3654, sections.sum(&:verses)
  end

  test "every section has a year, a place, a state and verses" do
    DoctrineAndCovenants.sections.each do |section|
      assert_includes 1820..1920, section.year, section.reference
      assert section.place.present?, section.reference
      assert section.state.present?, section.reference
      assert_operator section.verses, :>, 0, section.reference
    end
  end

  test "knows the sections this site describes in detail" do
    section = ->(number) { DoctrineAndCovenants.sections.find { |candidate| candidate.number == number } }

    assert_equal [ 1832, "Hiram", "Ohio", 119 ], section.(76).to_a.drop(1)
    assert_equal [ 1836, "Kirtland", "Ohio" ], section.(110).to_a[1, 3]
    assert_equal [ 1839, "Liberty", "Missouri" ], section.(121).to_a[1, 3]
    assert_equal [ 1847, "Winter Quarters", "Nebraska" ], section.(136).to_a[1, 3]
    assert_equal [ 1918, "Salt Lake City", "Utah" ], section.(138).to_a[1, 3]
  end

  test "groups the less common states as elsewhere" do
    by_number = DoctrineAndCovenants.sections.index_by(&:number)

    assert_equal "Ohio", DoctrineAndCovenants.region(by_number[76])
    assert_equal "Elsewhere", DoctrineAndCovenants.region(by_number[111])
    assert_equal "Elsewhere", DoctrineAndCovenants.region(by_number[138])
  end

  test "links to the official edition" do
    section = DoctrineAndCovenants.sections.first
    assert_equal "D&C 1", section.reference
    assert_equal "https://www.churchofjesuschrist.org/study/scriptures/dc-testament/dc/1?lang=eng", section.official_url
  end
end

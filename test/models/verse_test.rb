require "test_helper"

class VerseTest < ActiveSupport::TestCase
  setup do
    @section = create_revelation(13)
  end

  test "belongs to a revelation and needs a number and text" do
    assert @section.verses.build(number: 1, text: "Upon you my fellow servants").valid?
    assert_not @section.verses.build(number: 1).valid?
    assert_not @section.verses.build(text: "No number").valid?
  end

  test "a verse number is used once per revelation" do
    @section.verses.create!(number: 1, text: "First")
    assert_not @section.verses.build(number: 1, text: "Again").valid?
    assert create_revelation(76).verses.build(number: 1, text: "Another section").valid?
  end

  test "a revelation lists its verses in order and takes them with it" do
    @section.verses.create!(number: 2, text: "Second")
    @section.verses.create!(number: 1, text: "First")

    assert_equal %w[First Second], @section.verses.map(&:text)
    assert_difference("Verse.count", -2) { @section.destroy }
  end

  test "a revelation can be found by words in its verses" do
    @section.verses.create!(number: 1, text: "I confer the Priesthood of Aaron")
    assert_equal [ @section ], Revelation.matching("priesthood of Aaron").to_a
  end

  test "links to the official edition" do
    assert_equal "https://www.churchofjesuschrist.org/study/scriptures/dc-testament/dc/13?lang=eng", @section.official_url
    assert_nil Revelation.new.official_url
  end
end

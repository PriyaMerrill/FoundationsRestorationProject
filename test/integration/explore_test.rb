require "test_helper"

# Searches the real seed content, the way a visitor would.
class ExploreTest < ActionDispatch::IntegrationTest
  setup do
    capture_io { Rails.application.load_seed }
  end

  def results_for(query)
    get explore_path(q: query)
    assert_response :success
    css_select("section[aria-labelledby]").to_h do |section|
      [ section.at("h2").text.strip.split.first, section.css("a.card span:first-child").map { |node| node.text.strip } ]
    end
  end

  test "without a search it lists the whole database by type" do
    get explore_path

    assert_select "section#events a.record-link", count: Event.count
    assert_select "section#people a.record-link", count: Person.count
    assert_select "p[role=status]", text: /#{Event.count + Place.count + Person.count + Revelation.count} records/
  end

  test "Joseph Smith comes first among the people" do
    results = results_for("Joseph Smith")
    assert_equal "Joseph Smith", results.fetch("People").first
    assert_operator results.fetch("Events").size, :>, 10
  end

  test "Emma Smith finds her and the events she took part in" do
    results = results_for("Emma Smith")
    assert_equal [ "Emma Smith" ], results.fetch("People")
    assert_includes results.fetch("Events"), "The Relief Society is organized"
  end

  test "Liberty Jail finds the event, the place, the people and the revelations" do
    results = results_for("Liberty Jail")

    assert_equal "Imprisonment in Liberty Jail", results.fetch("Events").first
    assert_includes results.fetch("Places"), "Liberty"
    assert_includes results.fetch("People"), "Hyrum Smith"
    assert_equal [ "Doctrine and Covenants 121", "Doctrine and Covenants 122", "Doctrine and Covenants 123" ], results.fetch("Revelations").sort
  end

  test "Doctrine and Covenants 76 finds the section, however it is written" do
    [ "Doctrine and Covenants 76", "D&C 76" ].each do |query|
      results = results_for(query)
      assert_equal [ "Doctrine and Covenants 76" ], results.fetch("Revelations"), "searching for #{query}"
      assert_includes results.fetch("Events"), "The vision of the degrees of glory"
    end
  end

  test "Book of Mormon translation finds the translation events" do
    events = results_for("Book of Mormon translation").fetch("Events")
    assert_includes events, "Book of Mormon translation completed"
    assert_includes events, "Translation resumes with Oliver Cowdery as scribe"
  end

  test "Nauvoo Temple finds the temple's events and the place" do
    results = results_for("Nauvoo Temple")
    assert_includes results.fetch("Events"), "The Saints are commanded to build the Nauvoo Temple"
    assert_includes results.fetch("Places"), "Nauvoo"
  end

  test "results link to the record pages and show a summary" do
    get explore_path(q: "Liberty Jail")
    assert_select "a.card[href=?]", event_path("liberty-jail"), text: /December 1, 1838/
    assert_select "p[role=status]", text: /results? for/
  end

  test "a search with no matches says so" do
    get explore_path(q: "zzzz")
    assert_select "p", text: /Nothing matches/
    assert_select "section[aria-labelledby]", count: 0
  end
end

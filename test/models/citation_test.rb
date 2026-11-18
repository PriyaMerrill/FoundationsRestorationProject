require "test_helper"

class CitationTest < ActiveSupport::TestCase
  test "can cite a source for any kind of record" do
    papers = create_source
    records = [ create_event, create_place, create_person, create_revelation ]
    records.each { |record| record.citations.create!(source: papers, page: "12") }

    records.each { |record| assert_equal [ papers ], record.sources.to_a }
    assert_equal 4, papers.citations.count
  end

  test "requires a source" do
    assert_not Citation.new(citable: create_event).valid?
  end
end

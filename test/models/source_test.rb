require "test_helper"

class SourceTest < ActiveSupport::TestCase
  test "requires a title" do
    assert_not Source.new.valid?
  end

  test "is secondary unless marked primary" do
    assert create_source.kind_secondary?
    assert create_source("Journal", kind: "primary").kind_primary?
  end

  test "deleting a source removes its citations" do
    papers = create_source
    create_event.citations.create!(source: papers)
    assert_difference "Citation.count", -1 do
      papers.destroy
    end
  end
end

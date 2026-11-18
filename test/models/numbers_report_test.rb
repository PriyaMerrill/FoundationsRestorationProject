require "test_helper"

class NumbersReportTest < ActiveSupport::TestCase
  setup do
    @kirtland = create_place(state: "Ohio", latitude: 41.6, longitude: -81.3, start_year: 1831, end_year: 1838)
    @liberty = create_place("Liberty", state: "Missouri")
    @vision = create_revelation(76, received_on: Date.new(1832, 2, 16), place: @kirtland)
    @olive_leaf = create_revelation(88, received_on: Date.new(1832, 12, 27), place: @kirtland)
    @visions = create_revelation(110, received_on: Date.new(1836, 4, 3), place: @kirtland)
    @letter = create_revelation(121, received_on: Date.new(1839, 3, 20), place: @liberty)
    @undated = create_revelation(999)

    @dedication = create_event(place: @kirtland)
    @jail = create_event("Liberty Jail", start_date: Date.new(1838, 12, 1), category: "persecution", period: "missouri", place: @liberty)

    MembershipEstimate.create!(year: 1836, members: 13_293)
    MembershipEstimate.create!(year: 1838, members: 17_881)
  end

  test "membership growth has one point per year" do
    points = NumbersReport.new.membership_growth
    assert_equal %w[1836 1838], points.map(&:label)
    assert_equal [ 13_293, 17_881 ], points.map(&:value)
    assert_match "13,293", points.first.detail
  end

  test "revelations by place counts sections and links to the records" do
    points = NumbersReport.new.revelations_by_place

    assert_equal [ [ "Kirtland", 3 ], [ "Liberty", 1 ] ], points.map { |point| [ point.label, point.value ] }
    assert_equal [ @kirtland, @vision, @olive_leaf, @visions ], points.first.records
  end

  test "revelations by year fills quiet years with zero and skips undated sections" do
    points = NumbersReport.new.revelations_by_year

    assert_equal (1832..1839).map(&:to_s), points.map(&:label)
    assert_equal [ 2, 0, 0, 0, 1, 0, 0, 1 ], points.map(&:value)
  end

  test "the year range narrows every chart" do
    report = NumbersReport.new(from: "1836", to: "1837")

    assert_equal [ "1836" ], report.revelations_by_year.map(&:label)
    assert_equal [ "1836" ], report.membership_growth.map(&:label)
    assert_equal [ @dedication ], report.events
  end

  test "a reversed year range is swapped and out-of-range years are clamped" do
    report = NumbersReport.new(from: "1900", to: "1700")
    assert_equal 1820..1850, report.year_range
  end

  test "filters by period, category and place" do
    assert_equal [ @jail ], NumbersReport.new(period: "missouri").events
    assert_equal [ @letter ], NumbersReport.new(period: "missouri").revelations
    assert_equal [ @jail ], NumbersReport.new(category: "persecution").events
    assert_equal [ @vision, @olive_leaf, @visions ], NumbersReport.new(place: "kirtland").revelations
  end

  test "ignores unknown filter values" do
    report = NumbersReport.new(period: "atlantis", category: "sports", place: "nowhere")
    assert_not report.filtered?
    assert_equal 2, report.events.size
  end

  test "compares the periods on separate measures" do
    comparison = NumbersReport.new.period_comparison
    value = ->(title, label) { comparison.fetch(title).find { |point| point.label == label }&.value }

    assert_equal [ "Events", "Revelations", "Temple events", "Members at the period's end" ], comparison.keys
    assert_equal 1, value.call("Events", "Ohio")
    assert_equal 3, value.call("Revelations", "Ohio")
    assert_equal 1, value.call("Revelations", "Missouri")
    assert_equal 1, value.call("Temple events", "Ohio")
    assert_equal 13_293, value.call("Members at the period's end", "Ohio")
    assert_equal 17_881, value.call("Members at the period's end", "Missouri")
  end

  test "a revelation takes its period from its place, or its year" do
    assert_equal "ohio", @vision.period
    assert_equal "missouri", @letter.period
    assert_equal "nauvoo", Revelation.new(received_on: Date.new(1844, 6, 27)).period
    assert_nil @undated.period
  end

  test "expansion places need coordinates and a first year" do
    assert_equal [ @kirtland ], NumbersReport.new.expansion_places.to_a
  end
end

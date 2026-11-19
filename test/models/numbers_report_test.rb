require "test_helper"

class NumbersReportTest < ActiveSupport::TestCase
  setup do
    MembershipEstimate.create!(year: 1837, members: 16_282)
    MembershipEstimate.create!(year: 1838, members: 17_881)
    MembershipEstimate.create!(year: 1839, members: 16_460)
    MembershipEstimate.create!(year: 1841, members: 19_856)
  end

  test "membership growth has one point per year" do
    points = NumbersReport.new.membership_growth

    assert_equal %w[1837 1838 1839 1841], points.map(&:label)
    assert_equal 16_282, points.first.value
    assert_match "16,282", points.first.detail
  end

  test "membership change compares each year with the one before, in green or red" do
    points = NumbersReport.new.membership_change

    assert_equal %w[1838 1839], points.map(&:label), "1841 has no estimate for the year before"
    assert_equal [ 1_599, -1_421 ], points.map(&:value)
    assert_equal [ NumbersReport::GAIN, NumbersReport::LOSS ], points.map(&:color)
    assert_match "1,421 fewer", points.last.detail
  end

  test "sections by year counts the whole Doctrine and Covenants within the years charted" do
    chart = NumbersReport.new.sections_by_year
    counts = chart[:points].to_h { |point| [ point.label, point.value ] }

    assert_equal "1823", chart[:points].first.label
    assert_equal "1847", chart[:points].last.label
    assert_equal 37, counts["1831"]
    assert_equal 0, counts["1840"], "quiet years show as gaps"
    assert_equal 137, counts.values.sum, "section 138 (1918) is outside the range"
  end

  test "sections by year splits each year by state, and the parts add up" do
    chart = NumbersReport.new.sections_by_year

    assert_equal [ "New York", "Pennsylvania", "Ohio", "Missouri", "Illinois", "Elsewhere" ], chart[:series].map(&:name)
    chart[:points].each_with_index do |point, index|
      assert_equal point.value, chart[:series].sum { |part| part.values[index] }, point.label
    end
    assert_equal NumbersReport::REGION_COLORS.fetch("Ohio"), chart[:series].find { |part| part.name == "Ohio" }.color
  end

  test "sections by place ranks the towns and gathers single sections into one bar" do
    points = NumbersReport.new.sections_by_place

    assert_equal [ "Kirtland, Ohio", 46 ], [ points.first.label, points.first.value ]
    assert_equal [ "Fayette, New York", "Hiram, Ohio", "Harmony, Pennsylvania" ], points[1, 3].map(&:label)
    assert_match(/\A\d+ other places\z/, points.last.label)
    assert_equal 137, points.sum(&:value)
    assert_equal NumbersReport::REGION_COLORS.fetch("Ohio"), points.first.color
  end

  test "a section links to its page on this site when there is one, otherwise to the official edition" do
    create_revelation(110)
    links = NumbersReport.new.sections_by_place.first.records

    assert_equal "/revelations/doctrine-and-covenants-110", links.find { |link| link.label == "D&C 110" }.url
    assert_match %r{\Ahttps://www\.churchofjesuschrist\.org/.+/dc/42}, links.find { |link| link.label == "D&C 42" }.url
  end

  test "the year range narrows every chart" do
    report = NumbersReport.new(from: "1838", to: "1839")

    assert_equal %w[1838 1839], report.membership_growth.map(&:label)
    assert_equal %w[1839], report.membership_change.map(&:label)
    assert_equal %w[1838 1839], report.sections_by_year[:points].map(&:label)
    assert_equal [ 8, 3 ], report.sections_by_year[:points].map(&:value)
    assert_equal [ "Far West, Missouri", "Liberty, Missouri", "1 other place" ], report.sections_by_place.map(&:label)
    assert report.filtered?
  end

  test "a reversed year range is swapped and out-of-range years are clamped" do
    assert_equal 1820..1850, NumbersReport.new(from: "1900", to: "1700").year_range
  end

  test "headline figures summarise membership and the sections" do
    highlights = NumbersReport.new.highlights.to_h { |figure, label| [ label, figure ] }

    assert_equal "16,282", highlights["members in 1837"]
    assert_equal "19,856", highlights["members in 1841"]
    assert_equal "137", highlights["Doctrine and Covenants sections, 1823–1847"]
    assert_equal "1831", highlights["the busiest year: 37 sections"]
  end

  test "years with nothing in them give empty charts, not errors" do
    report = NumbersReport.new(from: "1848", to: "1850")

    assert_empty report.membership_growth
    assert_empty report.sections_by_year[:points]
    assert_empty report.sections_by_place
    assert_empty report.highlights
  end

  test "expansion places need coordinates and a first year" do
    kirtland = create_place(latitude: 41.6, longitude: -81.3, start_year: 1831)
    create_place("Liberty")
    assert_equal [ kirtland ], NumbersReport.new.expansion_places.to_a
  end

  test "the place chart's key lists only the colours in the chart" do
    assert_equal [ "New York", "Pennsylvania", "Ohio", "Missouri", "Illinois", "Several places" ], NumbersReport.new.place_key.keys
    assert_equal [ "Missouri", "Several places" ], NumbersReport.new(from: "1838", to: "1839").place_key.keys
  end
end

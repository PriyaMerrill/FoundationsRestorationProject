require "test_helper"

class MembershipEstimateTest < ActiveSupport::TestCase
  test "requires a year and a member count" do
    assert_not MembershipEstimate.new.valid?
  end

  test "allows one estimate per year" do
    MembershipEstimate.create!(year: 1830, members: 280)
    assert_not MembershipEstimate.new(year: 1830, members: 300).valid?
  end

  test "is approximate by default and can name its source" do
    estimate = MembershipEstimate.create!(year: 1830, members: 280, source: create_source)
    assert estimate.is_approximate
    assert_equal "The Joseph Smith Papers", estimate.source.title
  end
end

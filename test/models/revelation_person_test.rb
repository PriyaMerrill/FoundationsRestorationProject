require "test_helper"

class RevelationPersonTest < ActiveSupport::TestCase
  test "a person is only listed once per revelation" do
    section = create_revelation
    joseph = create_person
    section.revelation_people.create!(person: joseph)
    assert_not section.revelation_people.build(person: joseph).valid?
  end
end

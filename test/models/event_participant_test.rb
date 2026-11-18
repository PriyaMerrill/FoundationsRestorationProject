require "test_helper"

class EventParticipantTest < ActiveSupport::TestCase
  test "a person is only listed once per event" do
    event = create_event
    joseph = create_person
    event.event_participants.create!(person: joseph)
    assert_not event.event_participants.build(person: joseph).valid?
  end

  test "is removed with its event" do
    event = create_event
    event.people << create_person
    assert_difference "EventParticipant.count", -1 do
      event.destroy
    end
  end
end

require "test_helper"

class EventRevelationTest < ActiveSupport::TestCase
  test "a revelation is only linked once per event" do
    event = create_event
    section = create_revelation
    event.event_revelations.create!(revelation: section)
    assert_not event.event_revelations.build(revelation: section).valid?
  end
end

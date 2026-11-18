require "test_helper"

class RecordPagesTest < ActionDispatch::IntegrationTest
  setup do
    @place = create_place(state: "Ohio", kinds: %w[temple])
    @person = create_person
    @revelation = create_revelation(110, received_on: Date.new(1836, 4, 3), place: @place)
    @source = create_source(url: "https://www.josephsmithpapers.org")
    @event = create_event(place: @place, summary: "The first temple was dedicated.")
    @event.event_participants.create!(person: @person, role: "Offered the dedicatory prayer")
    @event.revelations << @revelation
    @event.citations.create!(source: @source, note: "Journal")
  end

  test "an event page shows its details and links to related records" do
    get event_path(@event)

    assert_response :success
    assert_select "h1", text: "Kirtland Temple dedication"
    assert_select "p", text: /March 27, 1836/
    assert_select "a[href=?]", place_path(@place)
    assert_select "a[href=?]", person_path(@person), text: /Offered the dedicatory prayer/
    assert_select "a[href=?]", revelation_path(@revelation), text: /D&C 110/
    assert_select "a[href=?]", "https://www.josephsmithpapers.org"
  end

  test "place, person and revelation pages load and link back to the event" do
    [ place_path(@place), person_path(@person), revelation_path(@revelation) ].each do |path|
      get path
      assert_response :success, "#{path} did not load"
      assert_select "a[href=?]", event_path(@event)
    end
  end

  test "a record with no sources says so" do
    get person_path(@person)
    assert_select "p", text: /No sources have been recorded/
  end

  test "an unknown record is a 404" do
    get event_path("no-such-event")
    assert_response :not_found
  end
end

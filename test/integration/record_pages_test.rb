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

  test "a revelation page shows its verses, the first few open and the rest on request" do
    8.times { |index| @revelation.verses.create!(number: index + 1, text: "Verse text number #{index + 1}.") }

    get revelation_path(@revelation)

    assert_select "#text-heading", text: "The text"
    assert_select "section[aria-labelledby=text-heading] > div > ol > li", count: 5
    assert_select "details summary", text: /Show all 8 verses/
    assert_select "details ol[start='6'] li", count: 3
    assert_select "li#verse-7", text: /Verse text number 7\./
    assert_select "a[href=?]", "https://www.churchofjesuschrist.org/study/scriptures/dc-testament/dc/110?lang=eng"
    assert_select "a[href=?]", "https://openscriptureapi.org"
  end

  test "a short revelation shows every verse with nothing to expand" do
    @revelation.verses.create!(number: 1, text: "The only verse.")

    get revelation_path(@revelation)

    assert_select "li#verse-1", text: /The only verse\./
    assert_select "details", count: 0
  end

  test "a revelation without saved verses has no text section" do
    get revelation_path(@revelation)
    assert_select "#text-heading", count: 0
  end

  test "a person page shows their portrait with its caption, credit and source" do
    @person.images.create!(file_name: "people/joseph-smith.jpg", caption: "Joseph Smith. Oil painting, about 1842.",
      credit: "Artist uncertain. Wikimedia Commons.", license: "Public domain", source_url: "https://commons.wikimedia.org/wiki/File:Example.jpg")

    get person_path(@person)

    assert_select "figure img[alt='Portrait of Joseph Smith'][src*='joseph-smith']"
    assert_select "figcaption", text: /Oil painting, about 1842.*Artist uncertain/m
    assert_select "figcaption a[href=?]", "https://commons.wikimedia.org/wiki/File:Example.jpg", text: "Image source"
  end

  test "a person without a portrait, or whose image file is missing, shows no picture" do
    get person_path(@person)
    assert_select "figure", count: 0

    @person.images.create!(file_name: "people/not-a-real-file.jpg")
    get person_path(@person)
    assert_select "figure", count: 0
  end

  test "a person page shows their facts at a glance" do
    @person.update!(facts: [ { "label" => "Born", "value" => "December 23, 1805, Sharon, Vermont" }, { "label" => "Parents", "value" => "Joseph Smith Sr. and Lucy Mack Smith" } ])

    get person_path(@person)

    assert_select "#facts-heading", text: "At a glance"
    assert_select "dl dt", text: "Born"
    assert_select "dl dd", text: "December 23, 1805, Sharon, Vermont"
    assert_select "dl dd", text: "Joseph Smith Sr. and Lucy Mack Smith"
  end

  test "a place page shows its facts at a glance" do
    @place.update!(facts: [ { "label" => "County", "value" => "Lake County, Ohio" } ])

    get place_path(@place)
    assert_select "dl dd", text: "Lake County, Ohio"
  end

  test "a revelation page adds its number of verses to its facts" do
    @revelation.update!(facts: [ { "label" => "Kind", "value" => "Visions" } ])
    3.times { |index| @revelation.verses.create!(number: index + 1, text: "Verse #{index + 1}.") }

    get revelation_path(@revelation)

    assert_select "dl dt", text: "Kind"
    assert_select "dl dd", text: "Visions"
    assert_select "dl dt", text: "Verses"
    assert_select "dl dd", text: "3"
  end

  test "a record without facts has no at-a-glance box" do
    get person_path(@person)
    assert_select "#facts-heading", count: 0
  end
end

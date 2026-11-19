require "application_system_test_case"

# The visitor journey described in the project specification: from the
# timeline to Liberty Jail, on to the map, the revelations, a person, and trivia.
class VisitorJourneyTest < ApplicationSystemTestCase
  test "a visitor follows Liberty Jail across the whole site" do
    visit root_path
    click_on "Interactive Timeline"

    # Timeline: choose Liberty Jail and read it in the panel.
    assert_selector "h1", text: "Interactive Timeline"
    click_link "Imprisonment in Liberty Jail" # the card; its dot on the line is a button with a similar name

    within "aside[role=dialog]" do
      assert_selector "h2", text: "Imprisonment in Liberty Jail"
      assert_text "December 1, 1838 – April 6, 1839"
      assert_link "D&C 121"
      assert_link "D&C 122"
      assert_link "D&C 123"
      assert_text "Joseph Smith"
    end
    assert_current_path timeline_path(event: "liberty-jail")

    # Map: open the event's place.
    click_on "View Liberty on the map"

    assert_selector "h1", text: "Road Trip"
    assert_selector ".leaflet-marker-icon", minimum: 10
    within "aside[role=dialog]" do
      assert_selector "h2", text: "Liberty"
      assert_text "Imprisonment in Liberty Jail"

      # Revelations: read about Doctrine and Covenants 121.
      click_on "D&C 121"
    end

    assert_selector "h1", text: "Doctrine and Covenants 121"
    assert_text "March 20, 1839"
    assert_selector "h2", text: "Sources"

    # People: follow the revelation to Joseph Smith.
    within("section", text: "People") { click_on "Joseph Smith" }

    assert_selector "h1", text: "Joseph Smith"
    assert_link "Imprisonment in Liberty Jail"

    # Trivia: start a game from the main navigation.
    within("header") { click_on "Trivia" }
    click_on "Play General Restoration Trivia"

    assert_selector "h1", text: "General Restoration Trivia"
    assert_text "Question 1 of"
  end

  test "the panel closes with Escape and returns to the timeline" do
    visit timeline_path(event: "liberty-jail")
    assert_selector "aside[role=dialog] h2", text: "Imprisonment in Liberty Jail"

    send_keys :escape

    assert_no_selector "aside[role=dialog] h2"
    assert_current_path timeline_path
  end

  test "filtering the timeline keeps only matching events" do
    visit timeline_path
    within("ul[aria-labelledby=category-label]") { click_on "Temples" }

    assert_text "in Temples"
    assert_selector "ol a.card", text: "Kirtland Temple dedication"
    assert_no_selector "ol a.card", text: "Imprisonment in Liberty Jail"
  end

  test "marking a place as explored updates the map" do
    visit road_trip_path
    assert_text "0 of 15 explored"

    within("li[data-slug=kirtland]") { click_on "Kirtland" }
    within("aside[role=dialog]") { click_on "Mark as explored" }

    assert_text "1 of 15 explored"
    assert_selector "aside[role=dialog] button[aria-pressed=true]", text: "Explored"
  end

  test "choosing a chart bar lists the records behind it" do
    visit numbers_path

    within("section", text: "Revelations by location") do
      find("summary", text: "Show as a table").click
      assert_link "D&C 110"
    end
    assert_selector "canvas", minimum: 8
  end

  test "searching finds records of every type" do
    visit explore_path
    fill_in "Search the records", with: "Liberty Jail"
    click_on "Search"

    assert_text "results for"
    assert_selector "section#events a.card", text: "Imprisonment in Liberty Jail"
    assert_selector "section#revelations a.card", minimum: 3
  end

  test "choosing a dot on the timeline brings its event to the front" do
    visit timeline_path
    track = find("#period-ohio ol")
    dot = track.all("button.timeline-dot")[6]

    dot.click

    assert_selector "#period-ohio button.timeline-dot[aria-current=true]", count: 1
    assert_operator track.evaluate_script("this.scrollLeft"), :>, 0
  end
end

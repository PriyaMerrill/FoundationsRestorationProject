require "test_helper"

class SourcesPageTest < ActionDispatch::IntegrationTest
  test "explains the methodology and lists the bibliography" do
    papers = create_source("The Joseph Smith Papers", kind: "primary", url: "https://www.josephsmithpapers.org")
    create_source("Saints")
    create_event.citations.create!(source: papers)
    uncertain = create_event("Restoration of the Melchizedek Priesthood", start_date: Date.new(1829, 6, 1), date_precision: "approximate",
      category: "leadership", period: "new_york")

    get sources_path

    assert_response :success
    %w[approach dates figures accounts scope images bibliography].each { |anchor| assert_select "section##{anchor} h2" }
    assert_select "nav[aria-label='On this page'] a[href='#dates']"

    assert_select "section#dates td", text: /c\. 1829: Restoration of the Melchizedek Priesthood/
    assert_select "section#accounts a[href=?]", event_path(uncertain)
    assert_select "section#scope p", text: /2 events/
    assert_select "section#images p", text: "No images have been added yet."

    assert_select "section#bibliography h3", text: "Primary sources"
    assert_select "section#bibliography h4", text: "The Joseph Smith Papers"
    assert_select "section#bibliography a[href=?]", "https://www.josephsmithpapers.org"
    assert_select "section#bibliography span", text: "Cited by 1 entry"
  end

  test "loads with an empty database" do
    get sources_path
    assert_response :success
  end

  test "credits images where they exist" do
    place = create_place
    place.images.create!(file_name: "kirtland-temple.jpg", caption: "Kirtland Temple", year: 1880, credit: "Library of Congress", license: "Public domain")

    get sources_path
    assert_select "section#images li", text: /Kirtland Temple.*1880 · Library of Congress · Public domain/m
  end
end

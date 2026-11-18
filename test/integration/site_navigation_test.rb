require "test_helper"

class SiteNavigationTest < ActionDispatch::IntegrationTest
  test "every main page loads" do
    %w[/ /road-trip /timeline /numbers /trivia /explore /sources].each do |path|
      get path
      assert_response :success, "#{path} did not load"
    end
  end

  test "every page has the main navigation and a skip link" do
    get root_path
    assert_select "header nav[aria-label=Main] a", text: "Timeline"
    assert_select "a[href='#main']", text: "Skip to content"
    assert_select "footer a[href=?]", sources_path
  end

  test "the current section is marked in the navigation" do
    get timeline_path
    assert_select "nav a[aria-current=page]", text: "Timeline"
  end

  test "explore lists records and links to their pages" do
    create_event(place: create_place)
    get explore_path
    assert_select "a[href=?]", event_path("kirtland-temple-dedication")
    assert_select "a[href=?]", place_path("kirtland")
  end

  test "sources lists the bibliography by kind" do
    create_source("Journal", kind: "primary")
    create_source("Saints")
    get sources_path
    assert_select "h3", text: "Journal"
    assert_select "h3", text: "Saints"
  end
end

require "test_helper"

class MetadataTest < ActionDispatch::IntegrationTest
  test "every page describes itself for search engines and link previews" do
    get root_path

    assert_select "title", text: "Foundations of the Restoration"
    assert_select "meta[name=description][content*='early Latter-day Saint history']"
    assert_select "meta[property='og:title'][content='Foundations of the Restoration']"
    assert_select "meta[property='og:image'][content='http://www.example.com/share.png']"
    assert_select "meta[name='twitter:card'][content=summary_large_image]"
  end

  test "a record page is titled and described by the record" do
    event = create_event(summary: "The first temple of the Restoration was dedicated.")
    get event_path(event)

    assert_select "title", text: "Kirtland Temple dedication · Foundations of the Restoration"
    assert_select "meta[name=description][content='The first temple of the Restoration was dedicated.']"
    assert_select "meta[property='og:description'][content='The first temple of the Restoration was dedicated.']"
  end

  test "the share image, icon and error pages exist" do
    %w[share.png icon.png icon.svg 404.html 500.html 422.html 400.html].each do |file|
      assert Rails.public_path.join(file).exist?, "public/#{file} is missing"
    end
    assert_match "This page is not in the record", Rails.public_path.join("404.html").read
  end
end

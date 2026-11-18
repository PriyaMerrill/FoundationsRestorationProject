require "test_helper"

class ImageTest < ActiveSupport::TestCase
  test "requires a file name" do
    assert_not Image.new(imageable: create_place).valid?
  end

  test "separates historical and modern images" do
    kirtland = create_place
    old = kirtland.images.create!(file_name: "kirtland-temple-1880.jpg", year: 1880, credit: "Public domain")
    new = kirtland.images.create!(file_name: "kirtland-temple-today.jpg", is_modern: true)

    assert_equal [ old ], kirtland.images.historical.to_a
    assert_equal [ new ], kirtland.images.modern.to_a
  end
end

require "test_helper"

# Find buttons by the name a screen reader announces ("Play Who Am I?").
Capybara.enable_aria_label = true

# Tests that drive a real (headless) Chrome browser, so the JavaScript runs.
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1000 ]

  # System tests use the real seed content, like a visitor would see.
  setup do
    capture_io { Rails.application.load_seed }
  end
end

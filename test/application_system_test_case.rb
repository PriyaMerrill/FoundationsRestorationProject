require "test_helper"

# Find buttons by the name a screen reader announces ("Play Who Am I?").
Capybara.enable_aria_label = true

# Turn off slide and fade animations in tests, so a click never lands on
# something that is still moving.
Capybara.disable_animation = true

# Tests that drive a real (headless) Chrome browser, so the JavaScript runs.
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1000 ]

  # System tests use the real seed content, like a visitor would see.
  setup do
    capture_io { Rails.application.load_seed }
  end
end

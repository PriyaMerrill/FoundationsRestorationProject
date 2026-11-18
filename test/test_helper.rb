ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Builders for historical records, so each test states only what it cares about.
    def create_place(name = "Kirtland", **attrs)
      Place.create!(name: name, **attrs)
    end

    def create_person(name = "Joseph Smith", **attrs)
      Person.create!(name: name, **attrs)
    end

    def create_event(title = "Kirtland Temple dedication", **attrs)
      Event.create!({ title: title, start_date: Date.new(1836, 3, 27), category: "temples", period: "ohio" }.merge(attrs))
    end

    def create_revelation(section_number = 110, **attrs)
      Revelation.create!({ section_number: section_number, title: "Doctrine and Covenants #{section_number}" }.merge(attrs))
    end

    def create_source(title = "The Joseph Smith Papers", **attrs)
      Source.create!(title: title, **attrs)
    end
  end
end

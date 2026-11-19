require "test_helper"

# Loads the real seed files and checks the content hangs together.
class SeedsTest < ActiveSupport::TestCase
  setup do
    capture_io { Rails.application.load_seed }
  end

  test "loads a first version of the dataset" do
    assert_operator Place.count, :>=, 10
    assert_operator Person.count, :>=, 15
    assert_operator Event.count, :>=, 30
    assert_operator Revelation.count, :>=, 15
    assert_operator TriviaQuestion.count, :>=, 10
    assert MembershipEstimate.exists?(year: 1830)
  end

  test "running the seeds twice changes nothing" do
    counts = -> { [ Place, Person, Event, Revelation, Verse, Image, Source, Citation, EventParticipant, TriviaQuestion ].map(&:count) }
    before = counts.call
    capture_io { Rails.application.load_seed }
    assert_equal before, counts.call
  end

  test "every event, revelation, place and person cites a source" do
    [ Event, Revelation, Place, Person ].each do |model|
      uncited = model.where.missing(:citations).pluck(:slug)
      assert_empty uncited, "#{model.name} records without a source"
    end
    assert_empty MembershipEstimate.where(source: nil).pluck(:year)
  end

  test "every place is on the map" do
    assert_equal Place.count, Place.mapped.count
  end

  test "includes the seven milestone years" do
    years = Event.pluck(:start_date).map(&:year)
    [ 1820, 1823, 1829, 1830, 1836, 1844, 1847 ].each { |year| assert_includes years, year }
  end

  test "Kirtland tells its story" do
    kirtland = Place.find_by!(slug: "kirtland")
    dates = kirtland.events.map(&:display_date)

    assert_includes dates, "February 1831"
    assert_includes dates, "1833"
    assert_includes dates, "March 27, 1836"
    assert_includes dates, "April 3, 1836"
    assert_includes kirtland.revelations.map(&:section_number), 110
  end

  test "Liberty Jail connects to its people, revelations and place" do
    event = Event.find_by!(slug: "liberty-jail")

    assert_equal "liberty", event.place.slug
    assert_includes event.people.map(&:name), "Joseph Smith"
    assert_equal [ 121, 122, 123 ], event.revelations.map(&:section_number).sort
  end

  test "Doctrine and Covenants 76 has its date, place and people" do
    section = Revelation.find_by!(section_number: 76)

    assert_equal "February 16, 1832", section.display_date
    assert_equal "Hiram", section.place.name
    assert_equal [ "Joseph Smith", "Sidney Rigdon" ], section.people.map(&:name).sort
  end

  test "the Fayette trivia question accepts the right answer" do
    question = TriviaQuestion.find_by!(prompt: "Where was the Church formally organized on April 6, 1830?")

    assert question.correct?("Fayette, New York")
    assert_equal "church-organized", question.subject.slug
  end

  test "uncertain dates are shown as uncertain" do
    assert_equal "1820", Event.find_by!(slug: "first-vision").display_date
    assert_equal "c. 1829", Event.find_by!(slug: "melchizedek-priesthood-restored").display_date
  end

  test "loads the verses of every section" do
    assert_empty Revelation.where.not(section_number: nil).where.missing(:verses).pluck(:section_number)

    section = Revelation.find_by!(section_number: 76)
    assert_equal 119, section.verses.size
    assert_equal (1..119).to_a, section.verses.map(&:number)
    assert_equal 1, Revelation.find_by!(section_number: 13).verses.size
  end

  test "every portrait has its file, a caption, a credit, a licence and a source" do
    assert_operator Image.count, :>=, 1

    Image.includes(:imageable).find_each do |image|
      name = image.imageable.name
      assert image.available?, "#{name}: #{image.file_name} is not in app/assets/images"
      assert image.caption.present?, "#{name}: no caption"
      assert image.credit.present?, "#{name}: no credit"
      assert_equal "Public domain", image.license, "#{name}: licence"
      assert_match %r{\Ahttps://commons\.wikimedia\.org/wiki/File:}, image.source_url, "#{name}: source"
    end
    assert_equal Image.count, Person.joins(:images).distinct.count, "one portrait per person"
  end

  test "every place is a numbered stop on the road trip, in one unbroken sequence" do
    assert_equal (1..Place.count).to_a, Place.order(:trail_order).pluck(:trail_order)
    assert_equal %w[far-west hawns-mill jefferson-city nauvoo], Place.where(trail_order: 8..11).order(:trail_order).pluck(:slug)
    assert_equal %w[kanesville winter-quarters salt-lake-city], Place.where(trail_order: 13..15).order(:trail_order).pluck(:slug)
  end

  test "every event has a full write-up" do
    missing = Event.all.reject { |event| event.background.present? && event.account_paragraphs.size >= 2 && event.significance.present? }
    assert_empty missing.map(&:slug), "events without background, account and significance"
  end

  test "every person, place and revelation has a longer story in three parts" do
    [ Person, Place, Revelation ].each do |model|
      assert_empty model.all.reject { |record| record.story_sections.size == 3 }.map(&:slug), "#{model.name} records without a three-part story"
    end
  end

  test "every person, place and revelation has facts at a glance" do
    [ Person, Place, Revelation ].each do |model|
      assert_empty model.all.select { |record| record.fact_list.empty? }.map(&:slug), "#{model.name} records without facts"
    end

    assert_equal [ "Born", "December 23, 1805, Sharon, Vermont" ], Person.find_by!(slug: "joseph-smith").fact_list.first
    assert_includes Place.find_by!(slug: "kirtland").fact_list, [ "Recognition", "National Historic Landmark" ]
    assert_includes Revelation.find_by!(slug: "dc-76").fact_list, [ "Given to", "Joseph Smith and Sidney Rigdon" ]
  end

  test "people's dates of birth and death in their facts match their records" do
    Person.find_each do |person|
      facts = person.fact_list.to_h
      assert facts.fetch("Born").start_with?(person.birth_date.strftime("%B %-d, %Y")), "#{person.name}: born"
      assert facts.fetch("Died").start_with?(person.death_date.strftime("%B %-d, %Y")), "#{person.name}: died"
    end
  end
end

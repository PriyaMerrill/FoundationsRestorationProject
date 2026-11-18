# Loads the historical content from the YAML files in db/seeds/.
#
# Those files are the source of truth: edit them, then run `bin/rails db:seed`.
# It is safe to run again and again. Records are matched by slug and updated,
# and anything removed from a file is removed from the database.

require "yaml"

module HistorySeeds
  DIR = Rails.root.join("db/seeds")
  SUBJECT_TYPES = { "event" => Event, "place" => Place, "person" => Person, "revelation" => Revelation }.freeze

  module_function

  def run
    ActiveRecord::Base.transaction do
      load_sources
      load_places
      load_people
      load_revelations
      load_verses
      load_events
      load_membership
      load_trivia
    end
    report
  end

  # --- one loader per file ---

  def load_sources
    sync(Source, "sources")
  end

  def load_places
    sync(Place, "places") do |place, row|
      cite(place, row["sources"])
    end
  end

  def load_people
    sync(Person, "people") do |person, row|
      cite(person, row["sources"])
    end
  end

  def load_revelations
    sync(Revelation, "revelations", "place" => Place) do |revelation, row|
      revelation.people = lookup_all(Person, row["people"])
      cite(revelation, row["sources"])
    end
  end

  # The text of each revelation, from db/seeds/verses.yml (see lib/tasks/verses.rake).
  def load_verses
    return unless DIR.join("verses.yml").exist?
    saved = read("verses")

    Revelation.where.not(section_number: nil).find_each do |revelation|
      texts = saved[revelation.section_number] || []
      next if revelation.verses.pluck(:text) == texts

      revelation.verses.delete_all
      rows = texts.each_with_index.map { |text, index| { revelation_id: revelation.id, number: index + 1, text: text } }
      Verse.insert_all!(rows) if rows.any?
    end
  end

  def load_events
    sync(Event, "events", "place" => Place) do |event, row|
      event.revelations = lookup_all(Revelation, row["revelations"])

      # People may be listed as "slug" or as "slug: role".
      event.event_participants.destroy_all
      Array(row["people"]).each do |entry|
        slug, role = entry.is_a?(Hash) ? entry.first : [ entry, nil ]
        event.event_participants.create!(person: lookup(Person, slug), role: role)
      end

      cite(event, row["sources"])
    end
  end

  def load_membership
    rows = read("membership")
    almanac = lookup(Source, "church-almanac")

    rows.each do |row|
      estimate = MembershipEstimate.find_or_initialize_by(year: row["year"])
      estimate.update!(
        members: row["members"],
        note: row["note"],
        is_approximate: row.fetch("is_approximate", true),
        source: row["source"] ? lookup(Source, row["source"]) : almanac
      )
    end
    MembershipEstimate.where.not(year: rows.map { |row| row["year"] }).destroy_all
  end

  def load_trivia
    TriviaQuestion.mode_general.delete_all

    read("trivia").each do |row|
      type, slug = row["subject"].to_s.split("/", 2)
      subject = lookup(SUBJECT_TYPES.fetch(type), slug) if type

      TriviaQuestion.create!(row.except("subject").merge(mode: "general", subject: subject))
    end
  end

  # --- helpers ---

  def read(name)
    YAML.load_file(DIR.join("#{name}.yml"), permitted_classes: [ Date ]) || []
  end

  # Creates or updates one record per row, matched by slug, then removes
  # records that are no longer in the file. `references` maps a row key to
  # the model it points at (for example "place" => Place).
  def sync(model, name, references = {})
    rows = read(name)

    rows.each do |row|
      attributes = row.except("sources", "people", "revelations")
      references.each do |key, target|
        attributes[key] = attributes[key] && lookup(target, attributes[key])
      end

      record = model.find_or_initialize_by(slug: row.fetch("slug"))
      record.update!(blank_attributes(model, references.keys).merge(attributes))
      yield record, row if block_given?
    end

    model.where.not(slug: rows.map { |row| row["slug"] }).destroy_all
  end

  # Every content column set back to its default, so deleting a line from
  # a YAML file clears that value in the database.
  def blank_attributes(model, reference_keys)
    skip = %w[id slug created_at updated_at] + reference_keys.map { |key| "#{key}_id" }
    defaults = model.column_defaults.except(*skip)
    reference_keys.each { |key| defaults[key] = nil }
    defaults
  end

  def lookup(model, slug)
    model.find_by(slug: slug) || raise("db/seeds: no #{model.name} with slug #{slug.inspect}")
  end

  def lookup_all(model, slugs)
    Array(slugs).map { |slug| lookup(model, slug) }
  end

  # Sources may be listed as "slug" or as { source: slug, note: ..., page: ... }.
  def cite(record, entries)
    record.citations.destroy_all
    Array(entries).each do |entry|
      entry = { "source" => entry } unless entry.is_a?(Hash)
      record.citations.create!(source: lookup(Source, entry["source"]), note: entry["note"], page: entry["page"])
    end
  end

  def report
    counts = [ Place, Person, Event, Revelation, Verse, Source, MembershipEstimate, TriviaQuestion ].map do |model|
      "#{model.count} #{model.model_name.human.downcase.pluralize(model.count)}"
    end
    puts "Seeded: #{counts.join(', ')}"
  end
end

HistorySeeds.run

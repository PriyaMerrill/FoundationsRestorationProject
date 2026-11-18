# Downloads the text of each revelation in the database from the Open
# Scripture API (https://openscriptureapi.org) and saves it to
# db/seeds/verses.yml. Run it once, and again after adding revelations:
#
#   bin/rails verses:fetch
#   bin/rails db:seed
#
# Only the verse text is kept. The modern section headings, summaries and
# footnotes are not copied.
namespace :verses do
  desc "Fetch the verses of every revelation from the Open Scripture API into db/seeds/verses.yml"
  task fetch: :environment do
    require "net/http"
    require "json"
    require "yaml"

    path = Rails.root.join("db/seeds/verses.yml")
    saved = path.exist? ? (YAML.load_file(path) || {}) : {}

    Revelation.where.not(section_number: nil).order(:section_number).pluck(:section_number).each do |section|
      if saved[section].present?
        puts "D&C #{section}: already saved (#{saved[section].size} verses)"
        next
      end

      uri = URI("https://openscriptureapi.org/api/scriptures/v1/lds/en/book/doctrineandcovenants/#{section}")
      response = Net::HTTP.get_response(uri)
      abort "D&C #{section}: request failed with #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      verses = JSON.parse(response.body).dig("chapter", "verses").map { |verse| verse.fetch("text").squish }
      abort "D&C #{section}: no verses returned" if verses.empty?

      saved[section] = verses
      puts "D&C #{section}: fetched #{verses.size} verses"
      sleep 1 # be polite to a free service
    end

    header = <<~TEXT
      # The text of the Doctrine and Covenants sections in the database, by section number.
      # Downloaded from the Open Scripture API (https://openscriptureapi.org) by `bin/rails verses:fetch`.
      # Do not edit by hand; run the task again to add sections.
    TEXT
    path.write(header + saved.sort.to_h.to_yaml(line_width: -1))
    puts "Saved #{saved.values.sum(&:size)} verses for #{saved.size} sections to #{path.relative_path_from(Rails.root)}"
  end
end

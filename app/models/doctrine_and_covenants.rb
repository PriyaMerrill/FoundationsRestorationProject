# The whole Doctrine and Covenants, section by section: the year each was
# received, where, and its number of verses. Read from
# db/data/doctrine_and_covenants.yml. Unlike the Revelation records, which
# cover a selection, this is every section, so it is safe to count.
class DoctrineAndCovenants
  Section = Struct.new(:number, :year, :place, :state, :verses, keyword_init: true) do
    def reference
      "D&C #{number}"
    end

    def official_url
      "https://www.churchofjesuschrist.org/study/scriptures/dc-testament/dc/#{number}?lang=eng"
    end
  end

  PATH = Rails.root.join("db/data/doctrine_and_covenants.yml")

  # The states where most sections were received, in the order the Church moved through them.
  STATES = [ "New York", "Pennsylvania", "Ohio", "Missouri", "Illinois" ].freeze
  ELSEWHERE = "Elsewhere".freeze

  def self.sections
    @sections ||= YAML.load_file(PATH).map do |row|
      Section.new(number: row["section"], year: row["year"], place: row["place"], state: row["state"], verses: row["verses"])
    end.freeze
  end

  # "New York", ..., or "Elsewhere" for the few received in other states.
  def self.region(section)
    STATES.include?(section.state) ? section.state : ELSEWHERE
  end

  def self.regions
    STATES + [ ELSEWHERE ]
  end
end

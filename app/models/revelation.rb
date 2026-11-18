class Revelation < ApplicationRecord
  include Sluggable, Citable, Illustrated, PreciselyDated

  slug_from :title
  precise_date :received_on

  include Searchable

  searchable against: { title: "A", subjects: "B", summary: "B", context: "C" },
    associated: { place: :name, people: :name }

  belongs_to :place, optional: true
  has_many :revelation_people, dependent: :destroy
  has_many :people, through: :revelation_people
  has_many :event_revelations, dependent: :destroy
  has_many :events, through: :event_revelations
  has_many :trivia_questions, as: :subject, dependent: :nullify

  validates :title, presence: true
  validates :section_number, uniqueness: true, allow_nil: true,
    numericality: { only_integer: true, greater_than: 0 }

  scope :chronological, -> { order(:received_on, :section_number) }

  PERIOD_BY_STATE = {
    "New York" => "new_york", "Pennsylvania" => "new_york", "Ohio" => "ohio", "Missouri" => "missouri",
    "Illinois" => "nauvoo", "Iowa" => "westward_migration", "Nebraska" => "westward_migration", "Utah" => "westward_migration"
  }.freeze

  # The period of Church history this revelation belongs to: taken from
  # where it was received, or from its year when the place is not recorded.
  def period
    from_place = PERIOD_BY_STATE[place&.state]
    return from_place if from_place
    return unless received_on

    case received_on.year
    when ..1830 then "new_york"
    when 1831..1837 then "ohio"
    when 1838..1839 then "missouri"
    when 1840..1845 then "nauvoo"
    else "westward_migration"
    end
  end

  # "D&C 76"
  def reference
    "D&C #{section_number}" if section_number
  end
end

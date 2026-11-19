class Revelation < ApplicationRecord
  include Sluggable, Citable, Illustrated, PreciselyDated

  slug_from :title
  precise_date :received_on

  include Searchable, WithFacts

  searchable against: { title: "A", subjects: "B", summary: "B", context: "C" },
    associated: { place: :name, people: :name, verses: :text }

  belongs_to :place, optional: true
  has_many :revelation_people, dependent: :destroy
  has_many :people, through: :revelation_people
  has_many :event_revelations, dependent: :destroy
  has_many :events, through: :event_revelations
  has_many :trivia_questions, as: :subject, dependent: :nullify
  has_many :verses, -> { order(:number) }, dependent: :delete_all, inverse_of: :revelation

  validates :title, presence: true
  validates :section_number, uniqueness: true, allow_nil: true,
    numericality: { only_integer: true, greater_than: 0 }

  scope :chronological, -> { order(:received_on, :section_number) }

  # The official edition of this section on the Church's website.
  def official_url
    "https://www.churchofjesuschrist.org/study/scriptures/dc-testament/dc/#{section_number}?lang=eng" if section_number
  end

  # "D&C 76"
  def reference
    "D&C #{section_number}" if section_number
  end
end

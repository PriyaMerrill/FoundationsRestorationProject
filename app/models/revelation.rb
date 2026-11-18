class Revelation < ApplicationRecord
  include Sluggable, Citable, Illustrated, PreciselyDated

  slug_from :title
  precise_date :received_on

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

  # "D&C 76"
  def reference
    "D&C #{section_number}" if section_number
  end
end

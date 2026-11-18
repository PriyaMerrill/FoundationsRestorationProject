class Event < ApplicationRecord
  include Sluggable, Citable, Illustrated, PreciselyDated

  slug_from :title
  precise_date :start_date

  CATEGORIES = %w[revelations leadership temples migration missionary_work persecution scripture_translation].freeze
  PERIODS = %w[new_york ohio missouri nauvoo westward_migration].freeze

  # Prefixed (event.category_temples?, Event.period_ohio) so they don't
  # clash with the revelations association.
  enum :category, CATEGORIES.index_with(&:itself), prefix: true, validate: true
  enum :period, PERIODS.index_with(&:itself), prefix: true, validate: true

  belongs_to :place, optional: true
  has_many :event_participants, dependent: :destroy
  has_many :people, through: :event_participants
  has_many :event_revelations, dependent: :destroy
  has_many :revelations, through: :event_revelations
  has_many :trivia_questions, as: :subject, dependent: :nullify

  validates :title, :start_date, presence: true

  scope :chronological, -> { order(:start_date, :id) }
  scope :on_this_day, ->(date = Date.current) {
    date_precision_exact.where("EXTRACT(MONTH FROM start_date) = ? AND EXTRACT(DAY FROM start_date) = ?", date.month, date.day)
  }
end

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

  # "December 1, 1838 – April 6, 1839" when the event has an end date.
  def display_dates
    return display_date unless end_date && date_precision_exact?
    "#{display_date} – #{end_date.strftime('%B %-d, %Y')}"
  end

  # Finds events by their own text or by a connected person, place or
  # revelation. "D&C 76" and "section 76" match that section.
  scope :search, ->(query) {
    query = query.to_s.strip
    next all if query.blank?

    pattern = "%#{sanitize_sql_like(query)}%"
    section = query[/\A(?:d&c|dc|d and c|section|doctrine and covenants)\s*(\d+)\z/i, 1]

    matches = left_joins(:place, :people, :revelations).where(
      "events.title ILIKE :q OR events.summary ILIKE :q OR places.name ILIKE :q OR people.name ILIKE :q OR revelations.title ILIKE :q",
      q: pattern
    )
    matches = matches.or(left_joins(:place, :people, :revelations).where(revelations: { section_number: section })) if section

    where(id: matches.select(:id))
  }

  scope :chronological, -> { order(:start_date, :id) }
  scope :on_this_day, ->(date = Date.current) {
    date_precision_exact.where("EXTRACT(MONTH FROM start_date) = ? AND EXTRACT(DAY FROM start_date) = ?", date.month, date.day)
  }
end

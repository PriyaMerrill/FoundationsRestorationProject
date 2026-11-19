class Event < ApplicationRecord
  include Sluggable, Citable, Illustrated, PreciselyDated

  slug_from :title
  precise_date :start_date

  include Searchable

  searchable against: { title: "A", summary: "B", context: "C", background: "D", account: "D", significance: "D" },
    associated: { place: :name, people: :name, revelations: :title }

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

  # The timeline's search: the events that match, without changing their order.
  scope :search, ->(query) { query.to_s.strip.blank? ? all : where(id: matching(query).reorder(nil).pluck(:id)) }

  # The account of what happened, one string per paragraph.
  def account_paragraphs
    account.to_s.split(/\n\s*\n/).map(&:squish).compact_blank
  end

  # The events just before and after this one on the timeline.
  def previous_event
    Event.chronological.where("(start_date, id) < (?, ?)", start_date, id).last
  end

  def next_event
    Event.chronological.where("(start_date, id) > (?, ?)", start_date, id).first
  end

  scope :chronological, -> { order(:start_date, :id) }
end

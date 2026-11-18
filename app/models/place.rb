class Place < ApplicationRecord
  include Sluggable, Citable, Illustrated
  include Searchable

  searchable against: { name: "A", modern_name: "B", state: "B", summary: "B", significance: "C" }

  # A place can be more than one kind (Kirtland is a temple site and a revelation site).
  KINDS = %w[temple revelation_site settlement landmark].freeze

  has_many :events, dependent: :nullify
  has_many :revelations, dependent: :nullify
  has_many :people, -> { distinct }, through: :events

  validates :name, presence: true
  validates :latitude, numericality: { in: -90..90 }, allow_nil: true
  validates :longitude, numericality: { in: -180..180 }, allow_nil: true
  validate :kinds_are_known

  scope :of_kind, ->(kind) { where("? = ANY (kinds)", kind) }
  scope :mapped, -> { where.not(latitude: nil).where.not(longitude: nil) }
  scope :along_trail, -> { where.not(trail_order: nil).order(:trail_order) }

  EARTH_RADIUS_MILES = 3958.8

  # Straight-line ("as the crow flies") distance to another place, in miles.
  def miles_to(other)
    lat1, lng1, lat2, lng2 = [ latitude, longitude, other.latitude, other.longitude ].map { |degrees| degrees.to_f * Math::PI / 180 }
    a = Math.sin((lat2 - lat1) / 2)**2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin((lng2 - lng1) / 2)**2
    (2 * EARTH_RADIUS_MILES * Math.asin(Math.sqrt(a))).round
  end

  def years
    [ start_year, end_year ].compact.uniq.join("–")
  end

  private
    def kinds_are_known
      unknown = Array(kinds) - KINDS
      errors.add(:kinds, "has unknown values: #{unknown.join(', ')}") if unknown.any?
    end
end

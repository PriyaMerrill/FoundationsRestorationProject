class Place < ApplicationRecord
  include Sluggable, Citable, Illustrated

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

  private
    def kinds_are_known
      unknown = Array(kinds) - KINDS
      errors.add(:kinds, "has unknown values: #{unknown.join(', ')}") if unknown.any?
    end
end

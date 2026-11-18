# Church membership for one year, for the membership growth chart.
class MembershipEstimate < ApplicationRecord
  belongs_to :source, optional: true

  validates :year, presence: true, uniqueness: true
  validates :members, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :chronological, -> { order(:year) }
end

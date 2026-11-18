# One verse of a revelation's text.
class Verse < ApplicationRecord
  belongs_to :revelation

  validates :number, presence: true, uniqueness: { scope: :revelation_id }, numericality: { only_integer: true, greater_than: 0 }
  validates :text, presence: true
end

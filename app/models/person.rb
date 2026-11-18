class Person < ApplicationRecord
  include Sluggable, Citable, Illustrated

  has_many :event_participants, dependent: :destroy
  has_many :events, through: :event_participants
  has_many :revelation_people, dependent: :destroy
  has_many :revelations, through: :revelation_people
  has_many :places, -> { distinct }, through: :events

  validates :name, presence: true
end

class Person < ApplicationRecord
  include Sluggable, Citable, Illustrated
  include Searchable, WithFacts

  searchable against: { name: "A", roles: "B", biography: "C" }

  has_many :event_participants, dependent: :destroy
  has_many :events, through: :event_participants
  has_many :revelation_people, dependent: :destroy
  has_many :revelations, through: :revelation_people
  has_many :places, -> { distinct }, through: :events

  validates :name, presence: true

  # The picture shown for this person, if one has been added.
  def portrait
    images.find { |image| !image.is_modern }
  end
end

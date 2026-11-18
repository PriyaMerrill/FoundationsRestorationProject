class RevelationPerson < ApplicationRecord
  belongs_to :revelation
  belongs_to :person

  validates :person_id, uniqueness: { scope: :revelation_id }
end

class EventRevelation < ApplicationRecord
  belongs_to :event
  belongs_to :revelation

  validates :revelation_id, uniqueness: { scope: :event_id }
end

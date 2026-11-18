# Connects a Source to any record it supports (an event, place, person or revelation).
class Citation < ApplicationRecord
  belongs_to :source
  belongs_to :citable, polymorphic: true
end

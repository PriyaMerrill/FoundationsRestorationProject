# Lets a record have historical and present-day images.
module Illustrated
  extend ActiveSupport::Concern

  included do
    has_many :images, as: :imageable, dependent: :destroy
  end
end

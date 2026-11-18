# A picture attached to any record. Files live in app/assets/images.
class Image < ApplicationRecord
  belongs_to :imageable, polymorphic: true

  validates :file_name, presence: true

  scope :historical, -> { where(is_modern: false) }
  scope :modern, -> { where(is_modern: true) }
end

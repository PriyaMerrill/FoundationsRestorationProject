# A picture attached to any record. Files live in app/assets/images.
class Image < ApplicationRecord
  belongs_to :imageable, polymorphic: true

  validates :file_name, presence: true

  # True when the picture's file is in app/assets/images.
  def available?
    Rails.application.assets.load_path.find(file_name).present?
  end

  scope :historical, -> { where(is_modern: false) }
  scope :modern, -> { where(is_modern: true) }
end

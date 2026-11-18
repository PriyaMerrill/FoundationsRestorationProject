class Source < ApplicationRecord
  include Sluggable

  slug_from :title

  KINDS = %w[primary secondary].freeze

  enum :kind, KINDS.index_with(&:itself), prefix: true, validate: true

  has_many :citations, dependent: :destroy
  has_many :membership_estimates, dependent: :nullify

  validates :title, presence: true
end

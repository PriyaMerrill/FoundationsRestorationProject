# Lets a record be backed by sources.
module Citable
  extend ActiveSupport::Concern

  included do
    has_many :citations, as: :citable, dependent: :destroy
    has_many :sources, through: :citations
  end
end

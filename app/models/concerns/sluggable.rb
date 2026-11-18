# Gives a record a URL-friendly slug ("Liberty Jail" -> "liberty-jail").
# The slug is how seed files and URLs refer to a record.
#
#   include Sluggable
#   slug_from :title
module Sluggable
  extend ActiveSupport::Concern

  included do
    before_validation :set_slug
    validates :slug, presence: true, uniqueness: true
  end

  class_methods do
    def slug_from(attribute)
      @slug_source = attribute
    end

    def slug_source
      @slug_source || :name
    end
  end

  def to_param
    slug
  end

  private
    def set_slug
      self.slug = public_send(self.class.slug_source).to_s.parameterize if slug.blank?
    end
end

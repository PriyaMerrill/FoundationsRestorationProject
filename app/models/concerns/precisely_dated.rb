# Records how exactly a date is known, so the site never shows a
# made-up day or month for something only known to the year.
#
#   include PreciselyDated
#   precise_date :start_date
#
#   event.display_date  # => "March 27, 1836", "March 1836", "1836" or "c. 1836"
module PreciselyDated
  extend ActiveSupport::Concern

  PRECISIONS = %w[exact month year approximate].freeze

  included do
    enum :date_precision, PRECISIONS.index_with(&:itself), prefix: true, validate: true
  end

  class_methods do
    def precise_date(attribute)
      @precise_date_attribute = attribute
    end

    def precise_date_attribute
      @precise_date_attribute
    end
  end

  def display_date
    date = public_send(self.class.precise_date_attribute)
    return if date.blank?

    case date_precision
    when "exact"       then date.strftime("%B %-d, %Y")
    when "month"       then date.strftime("%B %Y")
    when "year"        then date.year.to_s
    when "approximate" then "c. #{date.year}"
    end
  end
end

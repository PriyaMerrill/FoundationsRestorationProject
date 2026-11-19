# Gives a record a short list of labelled facts for its "At a glance" box.
#
#   person.fact_list  # => [ [ "Born", "December 23, 1805, Sharon, Vermont" ], ... ]
module WithFacts
  extend ActiveSupport::Concern

  def fact_list
    Array(facts).filter_map do |fact|
      label, value = fact.values_at("label", "value")
      [ label, value ] if label.present? && value.present?
    end
  end
end

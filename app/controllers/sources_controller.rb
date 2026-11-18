class SourcesController < ApplicationController
  def index
    @primary = Source.kind_primary.includes(:citations).order(:title)
    @secondary = Source.kind_secondary.includes(:citations).order(:title)

    @counts = { events: Event.count, places: Place.count, people: Person.count, revelations: Revelation.count }
    @images = Image.includes(:imageable).order(:file_name)

    # Real entries used as examples of how uncertain dates are shown.
    @date_examples = Event.where.not(date_precision: "exact").chronological.group_by(&:date_precision).transform_values(&:first)
    @uncertain_event = Event.date_precision_approximate.chronological.first
  end
end

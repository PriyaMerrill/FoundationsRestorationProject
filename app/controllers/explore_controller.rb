class ExploreController < ApplicationController
  def show
    @query = params[:q].to_s.strip

    @groups =
      if @query.present?
        # Best matches first within each type.
        { "Events" => Event.matching(@query).includes(:place), "Places" => Place.matching(@query),
          "People" => Person.matching(@query), "Revelations" => Revelation.matching(@query).includes(:place) }
      else
        { "Events" => Event.chronological.includes(:place), "Places" => Place.order(:name),
          "People" => Person.order(:name), "Revelations" => Revelation.order(:section_number).includes(:place) }
      end.transform_values(&:to_a)

    @total = @groups.values.sum(&:size)
  end
end

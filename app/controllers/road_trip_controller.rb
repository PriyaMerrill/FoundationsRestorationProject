class RoadTripController < ApplicationController
  def show
    # Road-trip stops first, in route order, then the other places by name.
    @places = Place.mapped.order(Arel.sql("trail_order IS NULL, trail_order, name"))
    @stops = @places.select(&:trail_order)
    @route_miles = @stops.each_cons(2).sum { |from, to| from.miles_to(to) }

    # /road-trip?place=kirtland opens that place's panel straight away.
    @open_place = Place.find_by(slug: params[:place]) if params[:place].present?
  end
end

class ExploreController < ApplicationController
  def show
    @places = Place.order(:name)
    @people = Person.order(:name)
    @events = Event.chronological
    @revelations = Revelation.order(:section_number)
  end
end

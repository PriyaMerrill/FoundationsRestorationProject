class PagesController < ApplicationController
  def home
    today = Date.current

    @on_this_day = Event.on_this_day(today).chronological.first
    @featured_event = @on_this_day || pick_for(today, Event.chronological)
    @featured_person = pick_for(today, Person.order(:name))
    @featured_revelation = pick_for(today, Revelation.order(:section_number))

    @counts = { "events" => Event.count, "places" => Place.count, "people" => Person.count, "revelations" => Revelation.count }
  end

  private
    # Picks a different record each day, and the same one all day.
    def pick_for(date, scope)
      count = scope.count
      scope.offset(date.yday % count).first if count.positive?
    end
end

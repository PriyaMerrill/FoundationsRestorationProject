class PagesController < ApplicationController
  def home
    today = Date.current

    # Shown only on days when something in the database happened.
    @on_this_day = Event.on_this_day(today).chronological.first

    @featured_place = pick_for(today, Place.mapped.order(:name))
    @featured_person = pick_for(today, Person.order(:name))
    @featured_revelation = pick_for(today, Revelation.where.not(section_number: nil).order(:section_number))
  end

  private
    # Picks a different record each day, and the same one all day.
    def pick_for(date, scope)
      count = scope.count
      scope.offset(date.yday % count).first if count.positive?
    end
end

class PagesController < ApplicationController
  def home
    today = Date.current

    @featured_event = pick_for(today, Event.chronological)
    @featured_person = pick_for(today, Person.includes(:images).order(:name))
    @featured_revelation = pick_for(today, Revelation.where.not(section_number: nil).order(:section_number))
  end

  private
    # Picks a different record each day, and the same one all day.
    def pick_for(date, scope)
      count = scope.count
      scope.offset(date.yday % count).first if count.positive?
    end
end

class TimelineController < ApplicationController
  def show
    @category = params[:category].presence_in(Event::CATEGORIES)
    @query = params[:q].to_s.strip

    events = Event.chronological.includes(:place, :people)
    events = events.where(category: @category) if @category
    events = events.search(@query) if @query.present?

    # { "new_york" => [events], "ohio" => [events], ... } in historical order.
    @events_by_period = Event::PERIODS.index_with { |period| events.select { |event| event.period == period } }.reject { |_, list| list.empty? }
    @total = @events_by_period.values.sum(&:size)

    # /timeline?event=liberty-jail opens that event's panel straight away.
    @open_event = Event.find_by(slug: params[:event]) if params[:event].present?
  end
end

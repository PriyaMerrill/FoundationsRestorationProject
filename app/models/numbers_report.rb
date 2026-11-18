# Builds the figures behind the "Restoration by the Numbers" charts.
#
# Every chart is a list of data points. Each point has a label, a value,
# a sentence of detail, and the records behind it, so a chart can always
# lead back to the history it counts.
class NumbersReport
  YEARS = (1820..1850)
  Point = Struct.new(:label, :value, :detail, :records, keyword_init: true)

  attr_reader :from, :to, :period, :category, :place

  def initialize(params = {})
    @from = params[:from].to_i.clamp(YEARS.first, YEARS.last) if params[:from].present?
    @to = params[:to].to_i.clamp(YEARS.first, YEARS.last) if params[:to].present?
    @from, @to = @to, @from if @from && @to && @from > @to
    @period = params[:period].presence_in(Event::PERIODS)
    @category = params[:category].presence_in(Event::CATEGORIES)
    @place = Place.find_by(slug: params[:place]) if params[:place].present?
  end

  def filtered?
    [ from, to, period, category, place ].any?
  end

  def year_range
    (from || YEARS.first)..(to || YEARS.last)
  end

  # --- the records being counted ---

  def events
    @events ||= begin
      scope = Event.chronological.includes(:place)
      scope = scope.where(period: period) if period
      scope = scope.where(category: category) if category
      scope = scope.where(place: place) if place
      scope.select { |event| year_range.cover?(event.start_date.year) }
    end
  end

  def revelations
    @revelations ||= begin
      scope = Revelation.chronological.includes(:place).where.not(received_on: nil)
      scope = scope.where(place: place) if place
      scope.select { |revelation| year_range.cover?(revelation.received_on.year) && (period.nil? || revelation.period == period) }
    end
  end

  def membership
    @membership ||= MembershipEstimate.chronological.includes(:source).select { |estimate| year_range.cover?(estimate.year) }
  end

  # --- the charts ---

  def membership_growth
    membership.map do |estimate|
      Point.new(label: estimate.year.to_s, value: estimate.members,
        detail: [ "About #{estimate.members.to_fs(:delimited)} members at the end of #{estimate.year}.", estimate.note ].compact.join(" "),
        records: [])
    end
  end

  def revelations_by_place
    revelations.group_by(&:place).reject { |place, _| place.nil? }.sort_by { |place, list| [ -list.size, place.name ] }.map do |place, list|
      Point.new(label: place.name, value: list.size,
        detail: "#{list.size} of the revelations in this database were received at #{place.name}.",
        records: [ place ] + list)
    end
  end

  def revelations_by_year
    by_year(revelations) { |revelation| revelation.received_on.year }.map do |year, list|
      Point.new(label: year.to_s, value: list.size, detail: "#{count_of(list, "revelation")} in this database dated #{year}.", records: list)
    end
  end

  def events_by_year
    by_year(events) { |event| event.start_date.year }.map do |year, list|
      Point.new(label: year.to_s, value: list.size, detail: "#{count_of(list, "event")} in this database dated #{year}.", records: list)
    end
  end

  # One small chart per measure, each comparing the five periods.
  def period_comparison
    periods = period ? [ period ] : Event::PERIODS

    {
      "Events" => periods.map { |name| period_point(name, events.select { |event| event.period == name }, "event") },
      "Revelations" => periods.map { |name| period_point(name, revelations.select { |revelation| revelation.period == name }, "revelation") },
      "Temple events" => periods.map { |name| period_point(name, events.select { |event| event.period == name && event.category == "temples" }, "temple event") },
      "Members at the period's end" => periods.filter_map { |name| membership_point(name) }
    }
  end

  # Places for the expansion map, with the years each was active.
  def expansion_places
    Place.mapped.where.not(start_year: nil).order(:start_year, :name)
  end

  private
    # Counts per year across the whole range, so quiet years show as gaps.
    def by_year(records, &year_of)
      grouped = records.group_by(&year_of)
      return [] if grouped.empty?

      (grouped.keys.min..grouped.keys.max).map { |year| [ year, grouped.fetch(year, []) ] }
    end

    def period_point(name, records, noun)
      Point.new(label: name.titleize, value: records.size, detail: "#{count_of(records, noun)} in the #{name.titleize} period.", records: records)
    end

    # Membership at the end of the last year with an event in that period.
    def membership_point(name)
      last_year = Event.where(period: name).maximum(:start_date)&.year
      estimate = last_year && membership.select { |candidate| candidate.year <= last_year }.last
      return unless estimate

      Point.new(label: name.titleize, value: estimate.members,
        detail: "About #{estimate.members.to_fs(:delimited)} members at the end of #{estimate.year}.", records: [])
    end

    def count_of(records, noun)
      "#{records.size} #{noun.pluralize(records.size)}"
    end
end

# Builds the figures behind the "Restoration by the Numbers" charts.
#
# Every chart here counts something complete: the Church's yearly
# membership estimates, or all 138 sections of the Doctrine and Covenants.
# Nothing counts the events, places or revelations chosen for this site,
# because a count of a selection says more about the selection than about
# history.
class NumbersReport
  YEARS = (1820..1850)
  Point = Struct.new(:label, :value, :detail, :records, :color, keyword_init: true)
  Series = Struct.new(:name, :color, :values, keyword_init: true)
  Link = Struct.new(:label, :type, :url, keyword_init: true)

  # One colour per state, checked for contrast and colour-blind safety.
  REGION_COLORS = {
    "New York" => "#2f6fa8", "Pennsylvania" => "#c08a1e", "Ohio" => "#238a63",
    "Missouri" => "#b4472e", "Illinois" => "#7558b0", DoctrineAndCovenants::ELSEWHERE => "#d0609a"
  }.freeze
  GAIN = "#1f7a4a".freeze
  LOSS = "#b4472e".freeze

  attr_reader :from, :to

  def initialize(params = {})
    @from = params[:from].to_i.clamp(YEARS.first, YEARS.last) if params[:from].present?
    @to = params[:to].to_i.clamp(YEARS.first, YEARS.last) if params[:to].present?
    @from, @to = @to, @from if @from && @to && @from > @to
  end

  def filtered?
    from.present? || to.present?
  end

  def year_range
    (from || YEARS.first)..(to || YEARS.last)
  end

  # --- what is being counted ---

  def membership
    @membership ||= MembershipEstimate.chronological.includes(:source).select { |estimate| year_range.cover?(estimate.year) }
  end

  def sections
    @sections ||= DoctrineAndCovenants.sections.select { |section| year_range.cover?(section.year) }
  end

  # Sections received outside the years the charts cover (section 138, in 1918).
  def sections_outside_range
    DoctrineAndCovenants.sections.reject { |section| YEARS.cover?(section.year) }
  end

  # --- headline figures ---

  def highlights
    first, last = membership.first, membership.last
    busiest = sections.group_by(&:year).max_by { |_, list| list.size }

    [
      (first && [ first.members.to_fs(:delimited), "members in #{first.year}" ]),
      (last && last != first && [ last.members.to_fs(:delimited), "members in #{last.year}" ]),
      (first && last && last != first && first.members.positive? && [ "#{(last.members.to_f / first.members).round}×", "growth in #{last.year - first.year} years" ]),
      (sections.any? && [ sections.size.to_s, "Doctrine and Covenants #{"section".pluralize(sections.size)}, #{sections.map(&:year).minmax.uniq.join("–")}" ]),
      (busiest && [ busiest.first.to_s, "the busiest year: #{busiest.last.size} sections" ])
    ].select(&:itself) # drops the figures that could not be worked out
  end

  # --- the charts ---

  def membership_growth
    membership.map do |estimate|
      Point.new(label: estimate.year.to_s, value: estimate.members,
        detail: [ "About #{estimate.members.to_fs(:delimited)} members at the end of #{estimate.year}.", estimate.note ].compact.join(" "),
        records: [])
    end
  end

  # How many members were gained, or lost, from one year to the next.
  def membership_change
    membership.each_cons(2).filter_map do |before, after|
      next unless after.year == before.year + 1

      change = after.members - before.members
      Point.new(label: after.year.to_s, value: change, color: (change.negative? ? LOSS : GAIN), records: [],
        detail: "#{change.negative? ? "About #{change.abs.to_fs(:delimited)} fewer" : "About #{change.to_fs(:delimited)} more"} members than at the end of #{before.year}.")
    end
  end

  # Sections of the Doctrine and Covenants by year, split by the state where each was received.
  def sections_by_year
    by_year = sections.group_by(&:year)
    return { points: [], series: [] } if by_year.empty?

    years = (by_year.keys.min..by_year.keys.max).to_a
    points = years.map do |year|
      list = by_year.fetch(year, [])
      Point.new(label: year.to_s, value: list.size, records: list.map { |section| section_link(section) },
        detail: list.empty? ? "No sections are dated #{year}." : "#{count_of(list, "section")} dated #{year}: #{places_summary(list)}.")
    end
    series = DoctrineAndCovenants.regions.filter_map do |region|
      values = years.map { |year| by_year.fetch(year, []).count { |section| DoctrineAndCovenants.region(section) == region } }
      Series.new(name: region, color: REGION_COLORS.fetch(region), values: values) if values.sum.positive?
    end

    { points: points, series: series }
  end

  # Sections by the town where each was received. Towns with one section share a bar.
  def sections_by_place
    grouped = sections.group_by { |section| [ section.place, section.state ] }
    major, minor = grouped.partition { |_, list| list.size > 1 }

    points = major.sort_by { |(place, _), list| [ -list.size, place ] }.map do |(place, state), list|
      Point.new(label: "#{place}, #{state}", value: list.size, color: REGION_COLORS.fetch(DoctrineAndCovenants.region(list.first)),
        detail: "#{count_of(list, "section")} received at #{place}, #{state}.", records: list.map { |section| section_link(section) })
    end

    others = minor.flat_map(&:last).sort_by(&:number)
    if others.any?
      points << Point.new(label: "#{others.size} other #{"place".pluralize(others.size)}", value: others.size, color: OTHER_PLACES,
        detail: "One section each: #{others.map { |section| "#{section.place}, #{section.state}" }.join("; ")}.",
        records: others.map { |section| section_link(section) })
    end
    points
  end

  OTHER_PLACES = "#64748b".freeze

  # The key for the place chart: only the colours that appear in it.
  def place_key
    colors = sections_by_place.map(&:color)
    key = REGION_COLORS.select { |_, color| colors.include?(color) }
    key["Several places"] = OTHER_PLACES if colors.include?(OTHER_PLACES)
    key
  end

  # Places for the expansion map, with the years each was active.
  def expansion_places
    Place.mapped.where.not(start_year: nil).order(:start_year, :name)
  end

  private
    # Links to this site's page for a section when it has one, otherwise to the official edition.
    def section_link(section)
      revelation = revelations_by_number[section.number]
      url = revelation ? Rails.application.routes.url_helpers.revelation_path(revelation) : section.official_url
      Link.new(label: section.reference, type: "Section", url: url)
    end

    def revelations_by_number
      @revelations_by_number ||= Revelation.where.not(section_number: nil).index_by(&:section_number)
    end

    def places_summary(list)
      list.group_by(&:place).map { |place, group| "#{group.size} at #{place}" }.to_sentence
    end

    def count_of(records, noun)
      "#{records.size} #{noun.pluralize(records.size)}"
    end
end

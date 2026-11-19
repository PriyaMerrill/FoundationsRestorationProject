# Builds a round of trivia questions for one game mode.
#
# General questions come from the TriviaQuestion table. The other modes
# write their questions from the historical records, so new events, places,
# people and revelations become new questions automatically.
class TriviaGame
  include Rails.application.routes.url_helpers

  # Each game has a kind (shown as a tag) and a look (its colour and icon on the trivia page).
  MODES = {
    "general" => { title: "General Restoration Trivia", description: "Multiple-choice questions across the whole story.", kind: "Multiple choice", look: "gold" },
    "guess_location" => { title: "Guess the Location", description: "Read about an event and name where it happened.", kind: "Places", look: "blue" },
    "dc_challenge" => { title: "Doctrine and Covenants Challenge", description: "Match a revelation to its description.", kind: "Scripture", look: "purple" },
    "who_am_i" => { title: "Who Am I?", description: "Name the person from as few clues as you can.", kind: "People", look: "red" },
    "chronology" => { title: "Chronology Challenge", description: "Put events in the order they happened.", kind: "Put in order", look: "green" }
  }.freeze
  DIFFICULTIES = TriviaQuestion::DIFFICULTIES

  # Harder games offer more answers to choose from, or more events to sort.
  OPTIONS = { "easy" => 3, "medium" => 4, "hard" => 5 }.freeze
  ROUND_LENGTH = 8
  CHRONOLOGY_ROUNDS = 4

  attr_reader :mode, :difficulty

  def initialize(mode:, difficulty: nil, random: Random.new)
    @mode = mode.to_s.presence_in(MODES.keys) || "general"
    @difficulty = difficulty.to_s.presence_in(DIFFICULTIES) || "medium"
    @random = random
  end

  def title
    MODES.fetch(mode)[:title]
  end

  def questions
    send("#{mode}_questions")
  end

  def as_json(*)
    { mode: mode, difficulty: difficulty, title: title, questions: questions }
  end

  private
    attr_reader :random

    def option_count
      OPTIONS.fetch(difficulty)
    end

    # --- General: written questions at the chosen difficulty ---

    def general_questions
      pick(TriviaQuestion.mode_general.where(difficulty: difficulty).includes(:subject).to_a).map do |question|
        choice_question(prompt: question.prompt, answer: question.answer, choices: question.choices.shuffle(random: random),
          explanation: question.explanation, link: link_for(question.subject))
      end
    end

    # --- Guess the Location: where did this event happen? ---

    def guess_location_questions
      names = Place.order(:name).pluck(:name)
      # Skip events whose title gives the place away ("Kirtland Temple dedication").
      events = Event.includes(:place).where.not(place: nil).reject { |event| title_names_place?(event) }

      pick(events).map do |event|
        choice_question(prompt: "Where did this take place?", stem: "#{event.title} (#{event.display_dates})",
          answer: event.place.name, choices: with_distractors(event.place.name, names),
          explanation: event.summary, link: link_for(event))
      end
    end

    def title_names_place?(event)
      event.place.name.split(/\W+/).any? { |word| word.length > 3 && event.title.downcase.include?(word.downcase) }
    end

    # --- Doctrine and Covenants Challenge: which section is this? ---

    def dc_challenge_questions
      revelations = Revelation.includes(:place).where.not(section_number: nil).where.not(summary: [ nil, "" ]).to_a
      references = revelations.map(&:reference)

      pick(revelations).map do |revelation|
        choice_question(prompt: "Which section is this?", stem: revelation.summary,
          answer: revelation.reference, choices: with_distractors(revelation.reference, references),
          explanation: [ received_sentence(revelation), revelation.context ].compact.join(" "),
          link: link_for(revelation))
      end
    end

    # "D&C 76 was received at Hiram on February 16, 1832."
    def received_sentence(revelation)
      date = revelation.display_date
      on = date && (revelation.date_precision_exact? ? "on #{date}" : revelation.date_precision_approximate? ? "around #{date.delete_prefix("c. ")}" : "in #{date}")
      details = [ revelation.place && "at #{revelation.place.name}", on ].compact
      "#{revelation.reference} was received #{details.join(" ")}." if details.any?
    end

    # --- Who Am I?: name the person from their clues ---

    def who_am_i_questions
      people = Person.order(:name).select { |person| person.clues.present? }
      names = people.map(&:name)

      pick(people).map do |person|
        choice_question(prompt: "Who am I?", clues: person.clues, answer: person.name,
          choices: with_distractors(person.name, names), explanation: person.biography, link: link_for(person))
      end
    end

    # --- Chronology Challenge: put events in order ---

    def chronology_questions
      # One event per year, so no two events in a question are too close to call.
      by_year = Event.chronological.group_by { |event| event.start_date.year }.values.map { |events| events.sample(random: random) }
      return [] if by_year.size < option_count

      Array.new(CHRONOLOGY_ROUNDS) do
        events = by_year.sample(option_count, random: random).sort_by(&:start_date)
        {
          kind: "order", prompt: "Put these events in order, earliest first.",
          items: events.shuffle(random: random).map { |event| { id: event.slug, label: event.title } },
          answer: events.map(&:slug),
          explanation: events.map { |event| "#{event.display_dates}: #{event.title}" },
          link: { label: "Explore the timeline", url: timeline_path }
        }
      end
    end

    # --- shared ---

    def pick(records)
      records.shuffle(random: random).first(ROUND_LENGTH)
    end

    def choice_question(**attributes)
      { kind: "choice" }.merge(attributes.compact)
    end

    # The right answer plus enough wrong ones, in a random order.
    def with_distractors(answer, pool)
      wrong = (pool.uniq - [ answer ]).sample(option_count - 1, random: random)
      ([ answer ] + wrong).shuffle(random: random)
    end

    # Events open on the timeline; other records open their own page.
    def link_for(record)
      case record
      when Event then { label: "See it on the timeline", url: timeline_path(event: record.slug) }
      when Place then { label: "Read about #{record.name}", url: place_path(record) }
      when Person then { label: "Read about #{record.name}", url: person_path(record) }
      when Revelation then { label: "Read about #{record.reference}", url: revelation_path(record) }
      end
    end
end

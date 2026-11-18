require "test_helper"

class TriviaGameTest < ActiveSupport::TestCase
  setup do
    @fayette = create_place("Fayette")
    @kirtland = create_place("Kirtland")
    @hiram = create_place("Hiram")
    @liberty = create_place("Liberty")
    %w[Nauvoo Harmony].each { |name| create_place(name) }

    @organized = create_event("Formal organization of the Church", slug: "church-organized", start_date: Date.new(1830, 4, 6),
      category: "leadership", period: "new_york", place: @fayette, summary: "Joseph Smith organized the Church.")
    @dedication = create_event(place: @kirtland)
    @vision = create_event("The vision of the degrees of glory", start_date: Date.new(1832, 2, 16), category: "revelations", place: @hiram)
    @jail = create_event("A winter in prison", start_date: Date.new(1838, 12, 1), category: "persecution", period: "missouri", place: @liberty)
    @first_vision = create_event("The First Vision", start_date: Date.new(1820, 3, 1), date_precision: "year", category: "revelations", period: "new_york")

    @section76 = create_revelation(76, received_on: Date.new(1832, 2, 16), place: @hiram, summary: "A vision of the kingdoms of glory.")
    [ 89, 110, 121, 136 ].each { |number| create_revelation(number, summary: "Summary of section #{number}.") }

    @joseph = create_person(clues: [ "I was born in Vermont.", "I translated the Book of Mormon." ], biography: "The first prophet.")
    %w[Emma\ Smith Hyrum\ Smith Oliver\ Cowdery Brigham\ Young].each { |name| create_person(name, clues: [ "A clue about #{name}." ]) }
    create_person("No Clues")

    @question = TriviaQuestion.create!(difficulty: "easy", prompt: "Where was the Church formally organized on April 6, 1830?",
      choices: [ "Palmyra, New York", "Fayette, New York", "Kirtland, Ohio", "Harmony, Pennsylvania" ], answer: "Fayette, New York",
      explanation: "At the Whitmer home.", subject: @organized)
    TriviaQuestion.create!(difficulty: "hard", prompt: "A hard one?", choices: %w[A B], answer: "A")
  end

  def game(mode, difficulty = "medium")
    TriviaGame.new(mode: mode, difficulty: difficulty, random: Random.new(1))
  end

  test "falls back to general trivia at medium difficulty" do
    fallback = TriviaGame.new(mode: "poker", difficulty: "impossible")
    assert_equal "general", fallback.mode
    assert_equal "medium", fallback.difficulty
  end

  test "general trivia asks the written questions at the chosen difficulty" do
    questions = game("general", "easy").questions

    assert_equal 1, questions.size
    question = questions.first
    assert_equal "Where was the Church formally organized on April 6, 1830?", question[:prompt]
    assert_equal "Fayette, New York", question[:answer]
    assert_equal @question.choices.sort, question[:choices].sort
    assert_equal({ label: "See it on the timeline", url: "/timeline?event=church-organized" }, question[:link])
  end

  test "guess the location asks where an event happened" do
    questions = game("guess_location").questions
    question = questions.find { |candidate| candidate[:stem].start_with?("Formal organization") }

    assert_equal "Fayette", question[:answer]
    assert_includes question[:choices], "Fayette"
    assert_equal 4, question[:choices].uniq.size
    assert_equal "Formal organization of the Church (April 6, 1830)", question[:stem]
  end

  test "guess the location skips events with no place or a title that names it" do
    stems = game("guess_location").questions.map { |question| question[:stem] }

    assert stems.none? { |stem| stem.start_with?("Kirtland Temple dedication") }
    assert stems.none? { |stem| stem.start_with?("The First Vision") }
    assert_equal 3, stems.size
  end

  test "the Doctrine and Covenants challenge asks which section a summary describes" do
    question = game("dc_challenge").questions.find { |candidate| candidate[:answer] == "D&C 76" }

    assert_equal "A vision of the kingdoms of glory.", question[:stem]
    assert_includes question[:choices], "D&C 76"
    assert_match "D&C 76 was received at Hiram on February 16, 1832.", question[:explanation]
    assert_equal "/revelations/doctrine-and-covenants-76", question[:link][:url]
  end

  test "who am I gives a person's clues and skips people without any" do
    questions = game("who_am_i").questions
    question = questions.find { |candidate| candidate[:answer] == "Joseph Smith" }

    assert_equal 5, questions.size
    assert_equal [ "I was born in Vermont.", "I translated the Book of Mormon." ], question[:clues]
    assert_includes question[:choices], "Joseph Smith"
    assert_not_includes questions.flat_map { |candidate| candidate[:choices] }, "No Clues"
  end

  test "chronology asks for events in date order, one per year" do
    questions = game("chronology").questions
    dates = Event.pluck(:slug, :start_date).to_h

    assert_equal 4, questions.size
    questions.each do |question|
      assert_equal "order", question[:kind]
      assert_equal 4, question[:items].size
      assert_equal question[:answer].sort, question[:items].map { |item| item[:id] }.sort
      assert_equal question[:answer], question[:answer].sort_by { |slug| dates.fetch(slug) }
      assert_equal 4, question[:answer].map { |slug| dates.fetch(slug).year }.uniq.size
    end
  end

  test "difficulty changes the number of choices" do
    assert_equal 3, game("who_am_i", "easy").questions.first[:choices].size
    assert_equal 5, game("who_am_i", "hard").questions.first[:choices].size
    assert_equal 3, game("chronology", "easy").questions.first[:items].size
  end

  test "a game without enough records has no questions" do
    Event.destroy_all
    assert_empty game("chronology").questions
    assert_empty game("guess_location").questions
  end
end

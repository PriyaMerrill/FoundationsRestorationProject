require "test_helper"

class TriviaTest < ActionDispatch::IntegrationTest
  setup do
    @fayette = create_place("Fayette")
    @organized = create_event("Formal organization of the Church", slug: "church-organized", start_date: Date.new(1830, 4, 6),
      category: "leadership", period: "new_york", place: @fayette)
    TriviaQuestion.create!(difficulty: "easy", prompt: "Where was the Church formally organized on April 6, 1830?",
      choices: [ "Palmyra, New York", "Fayette, New York", "Kirtland, Ohio" ], answer: "Fayette, New York",
      explanation: "At the Whitmer home.", subject: @organized)
  end

  test "the trivia page offers five games and three difficulties" do
    get trivia_path

    assert_response :success
    assert_select "form[action=?][method=get]", trivia_play_path
    assert_select "input[type=radio][name=difficulty]", count: 3
    assert_select "input[type=radio][value=medium][checked]"
    assert_select "button[name=mode]", count: 5
    assert_select "button[name=mode][value=chronology]"
    assert_select "h3", text: "Who Am I?"
  end

  test "the trivia page presents each game as a card with its own colour, kind and play button" do
    get trivia_path

    assert_select "article.game-card", count: 5
    assert_select "article.game-card.game-blue h3", text: "Guess the Location"
    assert_select "article.game-card.game-blue .game-card-kind", text: "Places"
    assert_select "article.game-card.game-blue .game-card-number", text: "Game 2"
    assert_select "button.play-button[aria-label='Play Chronology Challenge']", text: /Play/
    assert_select "[data-scores-target=best][data-mode=who_am_i]", text: "Not played yet"
    assert_select "[data-scores-target=summary]"
    assert_select "label.level-option", count: 3
    assert_select "body", text: /Harder games give you/, count: 0
  end

  test "the game page starts the quiz for the chosen mode and difficulty" do
    get trivia_play_path(mode: "guess_location", difficulty: "hard")

    assert_response :success
    assert_select "h1", text: "Guess the Location"
    assert_select "[data-controller=quiz][data-quiz-mode-value=guess_location][data-quiz-difficulty-value=hard]"
    assert_select "[data-quiz-url-value=?]", "/trivia/questions?difficulty=hard&mode=guess_location"
  end

  test "the game page falls back to general trivia for an unknown mode" do
    get trivia_play_path(mode: "poker")
    assert_select "h1", text: "General Restoration Trivia"
  end

  test "questions come back as JSON, and the Fayette question accepts Fayette" do
    get trivia_questions_path(mode: "general", difficulty: "easy")

    assert_response :success
    assert_equal "application/json", response.media_type
    body = response.parsed_body

    assert_equal "general", body["mode"]
    question = body["questions"].first
    assert_equal "Where was the Church formally organized on April 6, 1830?", question["prompt"]
    assert_equal "Fayette, New York", question["answer"]
    assert_includes question["choices"], "Fayette, New York"
    assert_equal "/timeline?event=church-organized", question["link"]["url"]
  end

  test "a game with too few records returns no questions" do
    get trivia_questions_path(mode: "chronology")
    assert_equal [], response.parsed_body["questions"]
  end
end

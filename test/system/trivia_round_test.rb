require "application_system_test_case"

class TriviaRoundTest < ApplicationSystemTestCase
  test "a visitor plays a whole round of general trivia" do
    visit trivia_path
    choose "Easy"
    click_on "Play General Restoration Trivia"

    assert_text "Question 1 of 5"

    5.times do |number|
      assert_text "Question #{number + 1} of 5"
      first(".quiz-choice").click

      # Every answer gets feedback, an explanation and a way to read more.
      assert_selector ".quiz-feedback", text: /Correct!|Not quite/
      assert_selector ".quiz-choice-correct", text: "Correct answer"
      assert_selector ".quiz-feedback a"

      click_on(number == 4 ? "See my score" : "Next question")
    end

    assert_selector "h2", text: /You scored \d of 5/
    assert_button "Play again"
    assert_link "Choose another game"

    # The best score shows on the trivia page afterwards.
    click_on "Choose another game"
    choose "Easy"
    assert_text(/Your best: \d of 5/)
  end

  test "who am I reveals clues one at a time" do
    visit trivia_play_path(mode: "who_am_i", difficulty: "easy")

    assert_selector "[data-quiz-target=clues] li", count: 1
    click_on "Give me another clue"
    assert_selector "[data-quiz-target=clues] li", count: 2
    assert_selector ".quiz-choice", count: 3
  end

  test "chronology checks an order made with the arrow buttons" do
    visit trivia_play_path(mode: "chronology", difficulty: "easy")

    assert_selector ".quiz-order-item", count: 3
    first(".quiz-move").ancestor("li").all(".quiz-move").last.click
    click_on "Check my order"

    assert_selector ".quiz-feedback", text: /right order/
    assert_button "Next question"
  end
end

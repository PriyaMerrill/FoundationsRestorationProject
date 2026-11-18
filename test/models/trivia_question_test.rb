require "test_helper"

class TriviaQuestionTest < ActiveSupport::TestCase
  def fayette_question(**attrs)
    TriviaQuestion.new({
      prompt: "Where was the Church formally organized on April 6, 1830?",
      choices: [ "Palmyra, New York", "Fayette, New York", "Kirtland, Ohio", "Harmony, Pennsylvania" ],
      answer: "Fayette, New York"
    }.merge(attrs))
  end

  test "is valid with a prompt, choices and an answer" do
    assert fayette_question.valid?
  end

  test "the answer must be one of the choices" do
    assert_not fayette_question(answer: "Nauvoo, Illinois").valid?
  end

  test "checks an answer" do
    question = fayette_question
    assert question.correct?("Fayette, New York")
    assert_not question.correct?("Kirtland, Ohio")
  end

  test "defaults to general mode at medium difficulty" do
    question = fayette_question
    assert question.mode_general?
    assert question.medium?
  end

  test "can point at the record it is about" do
    event = create_event("Organization of the Church", start_date: Date.new(1830, 4, 6), category: "leadership", period: "new_york")
    question = fayette_question(subject: event)
    question.save!
    assert_equal event, question.subject
    assert_equal [ question ], event.trivia_questions.to_a
  end
end

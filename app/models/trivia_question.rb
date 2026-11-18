class TriviaQuestion < ApplicationRecord
  MODES = %w[general guess_location dc_challenge who_am_i chronology].freeze
  DIFFICULTIES = %w[easy medium hard].freeze

  enum :mode, MODES.index_with(&:itself), prefix: true, validate: true
  enum :difficulty, DIFFICULTIES.index_with(&:itself), validate: true

  # The record this question is about, so feedback can link to it.
  belongs_to :subject, polymorphic: true, optional: true

  validates :prompt, :answer, presence: true
  validate :answer_is_one_of_the_choices

  def correct?(choice)
    choice.to_s.strip.casecmp?(answer.to_s.strip)
  end

  private
    def answer_is_one_of_the_choices
      return if choices.blank? || choices.include?(answer)
      errors.add(:answer, "must be one of the choices")
    end
end

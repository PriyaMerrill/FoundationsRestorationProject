class TriviaController < ApplicationController
  def index
  end

  def play
    @game = TriviaGame.new(mode: params[:mode], difficulty: params[:difficulty])
  end

  # The questions for one round, fetched by the quiz when a game starts.
  def questions
    render json: TriviaGame.new(mode: params[:mode], difficulty: params[:difficulty])
  end
end

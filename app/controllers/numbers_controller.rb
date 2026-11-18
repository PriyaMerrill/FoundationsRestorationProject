class NumbersController < ApplicationController
  def show
    @report = NumbersReport.new(params)
    @places = Place.order(:name)
    @membership_source = Source.find_by(slug: "church-almanac")
  end
end

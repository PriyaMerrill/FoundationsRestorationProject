class NumbersController < ApplicationController
  def show
    @report = NumbersReport.new(params)
    @membership_source = Source.find_by(slug: "church-almanac")
  end
end

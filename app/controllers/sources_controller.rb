class SourcesController < ApplicationController
  def index
    @primary = Source.kind_primary.order(:title)
    @secondary = Source.kind_secondary.order(:title)
  end
end

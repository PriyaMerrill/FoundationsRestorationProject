# Shows one historical record. The same controller serves places, people,
# events and revelations; the route decides which.
class RecordsController < ApplicationController
  MODELS = { "places" => Place, "people" => Person, "events" => Event, "revelations" => Revelation }.freeze

  def show
    model = MODELS.fetch(request.path.split("/")[1])
    @record = model.find_by!(slug: params[:id])
    render model.model_name.singular
  end
end

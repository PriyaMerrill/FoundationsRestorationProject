# Shows one historical record. The same controller serves places, people,
# events and revelations; the route decides which.
#
# A request from the slide-over panel (a Turbo Frame called "panel") gets a
# compact version of the record instead of the full page.
class RecordsController < ApplicationController
  MODELS = { "places" => Place, "people" => Person, "events" => Event, "revelations" => Revelation }.freeze
  PANELS = %w[event].freeze

  def show
    model = MODELS.fetch(request.path.split("/")[1])
    @record = model.find_by!(slug: params[:id])
    name = model.model_name.singular

    if turbo_frame_request_id == "panel" && PANELS.include?(name)
      render "records/panels/#{name}", layout: false
    else
      render name
    end
  end
end

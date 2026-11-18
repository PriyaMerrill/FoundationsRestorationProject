Rails.application.routes.draw do
  root "pages#home"

  # The main sections of the site.
  get "road-trip", to: "sections#road_trip", as: :road_trip
  get "timeline", to: "timeline#show", as: :timeline
  get "numbers", to: "sections#numbers", as: :numbers
  get "trivia", to: "sections#trivia", as: :trivia
  get "explore", to: "explore#show", as: :explore
  get "sources", to: "sources#index", as: :sources

  # One page per historical record, addressed by slug: /events/liberty-jail
  resources :places, :people, :events, :revelations, only: :show, controller: :records

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end

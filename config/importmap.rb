# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "leaflet" # @1.9.4
pin "visited_places"
pin "chart.js", to: "chart.umd.js" # @4.6.1, the self-contained build
pin "sortablejs", to: "sortable.esm.js" # @1.15.6
pin "trivia_scores"

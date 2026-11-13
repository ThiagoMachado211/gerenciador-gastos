# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "chart.js", to: "chart.js.js" # @4.5.1
pin "@kurkle/color", to: "@kurkle--color.js" # @0.3.4

pin "chartjs-helpers", to: "chartjs-helpers.js"

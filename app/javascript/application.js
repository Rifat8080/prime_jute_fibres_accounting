// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@popperjs/core"
import "flowbite"
import "./modals"
import Rails from "@rails/ujs"

Rails.start()

document.addEventListener("turbo:load", () => {
    // Initialize Flowbite components
    initFlowbite();
});


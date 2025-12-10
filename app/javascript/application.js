// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@popperjs/core"
import "flowbite"
import "./modals"

document.addEventListener("turbo:load", () => {
    // Initialize Flowbite components
    initFlowbite();
});


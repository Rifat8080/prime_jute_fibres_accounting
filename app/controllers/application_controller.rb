class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  layout :layout_by_resource

  private

  def layout_by_resource
    return "application" if controller_name == "posts" && action_name == "index"

    if user_signed_in?
      "authenticated"
    else
      "application"
    end
  end
end

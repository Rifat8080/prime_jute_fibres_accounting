class PostsController < ApplicationController
  before_action :authenticate_user!, only: [:dashboard]

  def index
    # Always render the public landing page at root, even when signed in.
  end

  def dashboard
    render :dashboard, layout: "authenticated"
  end
end

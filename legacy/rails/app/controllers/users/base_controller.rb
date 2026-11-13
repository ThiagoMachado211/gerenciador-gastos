class Users::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :disable_caching

  layout "internal"

  private

  def disable_caching
    response.headers["Cache-Control"] = "no-store"
  end
end

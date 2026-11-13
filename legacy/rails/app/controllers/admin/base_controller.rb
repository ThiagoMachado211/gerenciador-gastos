class Admin::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :disable_caching

  layout "internal"

  private

  def require_admin!
    return if current_user.admin?

    render "admin/forbidden", status: :forbidden
  end

  def disable_caching
    response.headers["Cache-Control"] = "no-store"
  end
end

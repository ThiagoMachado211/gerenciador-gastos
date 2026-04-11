class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?

  layout :layout_by_resource

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  def layout_by_resource
    devise_controller? ? "authentication" : "application"
  end

  def after_sign_in_path_for(resource)
    users_dashboard_path
  end
end
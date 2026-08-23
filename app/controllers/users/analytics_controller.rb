class Users::AnalyticsController < Users::BaseController
  def index
    redirect_to users_dashboard_path
  end
end
class Admin::DashboardController < Admin::BaseController
  def index
    @users_count = User.count
    @admins_count = User.where(admin: true).count
    @new_users_count = User.where(created_at: 30.days.ago..Time.current).count
    @recent_users = User.order(created_at: :desc, id: :desc).limit(8)
  end
end

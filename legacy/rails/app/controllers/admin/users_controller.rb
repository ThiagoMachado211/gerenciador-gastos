class Admin::UsersController < Admin::BaseController
  PER_PAGE = 25

  def index
    @users_count = User.count
    @total_pages = [ (@users_count.to_f / PER_PAGE).ceil, 1 ].max
    @page = (Integer(params[:page], exception: false) || 1).clamp(1, @total_pages)
    @users = User.order(created_at: :desc, id: :desc).offset((@page - 1) * PER_PAGE).limit(PER_PAGE)
  end
end

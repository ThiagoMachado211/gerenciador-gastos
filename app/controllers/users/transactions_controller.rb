class Users::TransactionsController < Users::BaseController
  def index
  end

  def new
  end

  def create
    redirect_to users_dashboard_path, notice: "Transação criada."
  end
end
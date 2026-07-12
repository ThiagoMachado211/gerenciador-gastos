class Users::TransactionsController < Users::BaseController
  def index
  end

  def new
  end

  def create
    redirect_to users_dashboard_path, notice: "Transação criada."
  end

  def edit
  end

  def update
    redirect_to users_transactions_path, notice: "Transação atualizada."
  end

  def destroy
    redirect_to users_transactions_path, notice: "Transação removida."
  end
end
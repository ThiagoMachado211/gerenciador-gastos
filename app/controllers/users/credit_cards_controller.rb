class Users::CreditCardsController < Users::BaseController
  def index
  end

  def new
  end

  def create
    redirect_to users_credit_cards_path, notice: "Cartão criado."
  end

  def edit
  end

  def update
    redirect_to users_credit_cards_path, notice: "Cartão atualizado."
  end

  def destroy
    redirect_to users_credit_cards_path, notice: "Cartão removido."
  end
end
class Users::CreditCardsController < Users::BaseController
  before_action :set_credit_card, only: %i[edit update destroy]

  def index
    @credit_cards = current_user.credit_cards.order(:name)
  end

  def new
    unless usage_checker.can_create_credit_card?
      redirect_to users_credit_cards_path,
                  alert: "Seu plano gratuito permite apenas 1 cartão."
      return
    end

    @credit_card = current_user.credit_cards.new
  end

  def create
    unless usage_checker.can_create_credit_card?
      redirect_to users_credit_cards_path,
                  alert: "Seu plano gratuito permite apenas 1 cartão."
      return
    end

    @credit_card = current_user.credit_cards.new(credit_card_params)

    if @credit_card.save
      redirect_to users_credit_cards_path,
                  notice: "Cartão cadastrado com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @credit_card.update(credit_card_params)
      redirect_to users_credit_cards_path,
                  notice: "Cartão atualizado com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @credit_card.destroy

    redirect_to users_credit_cards_path,
                notice: "Cartão removido com sucesso."
  end

  private

  def set_credit_card
    @credit_card = current_user.credit_cards.find(params[:id])
  end

  def credit_card_params
    params.require(:credit_card).permit(
      :name,
      :limit_cents,
      :closing_day,
      :due_day
    )
  end

  def usage_checker
    @usage_checker ||= Plans::UsageChecker.new(current_user)
  end
end
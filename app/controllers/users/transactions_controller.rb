class Users::TransactionsController < Users::BaseController
  def index
  end

  def new
    @transaction = current_user.transactions.new
    load_form_options
  end

  def create
    @transaction = current_user.transactions.new(transaction_params)
    load_form_options

    if @transaction.save
      redirect_to users_transactions_path,
                  notice: "Transação cadastrada com sucesso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
  end

  def destroy
  end

  private

  def load_form_options
    @categories = current_user.categories.order(:name)
    @credit_cards = current_user.credit_cards.order(:name)
  end

  def transaction_params
    params.require(:transaction).permit(
      :kind,
      :description,
      :amount_cents,
      :occurred_on,
      :installments_count,
      :category_id,
      :credit_card_id
    )
  end
end
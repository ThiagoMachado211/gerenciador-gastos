class Users::TransactionsController < Users::BaseController
  before_action :set_transaction, only: %i[edit update destroy]
  before_action :load_form_options, only: %i[new create edit update]

  def index
    @transactions = current_user.transactions
                                .includes(:category, :credit_card)
                                .recent_first

    @total_income_cents = @transactions.incomes.sum(:amount_cents)
    @total_expense_cents = @transactions.expenses.sum(:amount_cents)
    @balance_cents = @total_income_cents - @total_expense_cents
  end

  def new
    @transaction = current_user.transactions.new(
      occurred_on: Date.current,
      installments_count: 1,
      kind: "expense"
    )
  end

  def create
    @transaction = current_user.transactions.new(transaction_params)

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
    if @transaction.update(transaction_params)
      redirect_to users_transactions_path,
                  notice: "Transação atualizada com sucesso."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @transaction.destroy

    redirect_to users_transactions_path,
                notice: "Transação removida com sucesso."
  end

  private

  def set_transaction
    @transaction = current_user.transactions.find(params[:id])
  end

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
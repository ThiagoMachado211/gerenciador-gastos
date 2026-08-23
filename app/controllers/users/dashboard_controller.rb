class Users::DashboardController < Users::BaseController
  def index
    @reference_date = Date.current

    @transactions = current_user.transactions
                                .includes(:category, :credit_card)

    @month_transactions = @transactions.where(
      occurred_on: @reference_date.beginning_of_month..@reference_date.end_of_month
    )

    @recent_transactions = @transactions
                             .order(occurred_on: :desc, created_at: :desc)
                             .limit(8)

    @income_cents = @month_transactions
                      .where(kind: "income")
                      .sum(:amount_cents)

    @expense_cents = @month_transactions
                       .where(kind: "expense")
                       .sum(:amount_cents)

    @balance_cents = @income_cents - @expense_cents

    load_year_summary
    load_category_summary
  end

  private

  def load_year_summary
    year = @reference_date.year

    transactions = current_user.transactions.where(
      occurred_on: Date.new(year, 1, 1)..Date.new(year, 12, 31)
    )

    @monthly_summary = (1..12).map do |month|
      month_transactions = transactions.where(
        occurred_on: Date.new(year, month, 1)..Date.new(year, month, -1)
      )

      income = month_transactions
                 .where(kind: "income")
                 .sum(:amount_cents)

      expense = month_transactions
                  .where(kind: "expense")
                  .sum(:amount_cents)

      {
        month: month,
        income_cents: income,
        expense_cents: expense,
        balance_cents: income - expense
      }
    end
  end

  def load_category_summary
    @category_summary = current_user.transactions
                                    .where(kind: "expense")
                                    .where.not(category_id: nil)
                                    .joins(:category)
                                    .group("categories.name")
                                    .sum(:amount_cents)
                                    .sort_by { |_name, value| -value }
  end
end
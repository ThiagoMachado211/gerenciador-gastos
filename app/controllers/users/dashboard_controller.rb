class Users::DashboardController < Users::BaseController
  def index
    @reference_date = Date.current

    @transactions = current_user.transactions
                                .includes(:category, :credit_card)

    load_month_summary
    load_recent_transactions
    load_year_summary
    load_category_summary
  end

  private

  def load_month_summary
    @month_transactions = @transactions.where(
      occurred_on: @reference_date.beginning_of_month..@reference_date.end_of_month
    )

    @income_cents = @month_transactions
                      .where(kind: "income")
                      .sum(:amount_cents)

    @expense_cents = @month_transactions
                       .where(kind: "expense")
                       .sum(:amount_cents)

    @balance_cents = @income_cents - @expense_cents
  end

  def load_recent_transactions
    @recent_transactions = @transactions
                             .order(occurred_on: :desc, created_at: :desc)
                             .limit(8)
  end

  def load_year_summary
    year = @reference_date.year

    year_transactions = @transactions.where(
      occurred_on: Date.new(year, 1, 1)..Date.new(year, 12, 31)
    )

    @year_income_cents = year_transactions
                           .where(kind: "income")
                           .sum(:amount_cents)

    @year_expense_cents = year_transactions
                            .where(kind: "expense")
                            .sum(:amount_cents)

    @year_balance_cents =
      @year_income_cents - @year_expense_cents

    @monthly_summary = (1..12).map do |month|
      first_day = Date.new(year, month, 1)
      last_day = first_day.end_of_month

      month_transactions = year_transactions.where(
        occurred_on: first_day..last_day
      )

      income = month_transactions
                 .where(kind: "income")
                 .sum(:amount_cents)

      expense = month_transactions
                  .where(kind: "expense")
                  .sum(:amount_cents)

      {
        month: month,
        month_name: I18n.l(first_day, format: "%B"),
        income_cents: income,
        expense_cents: expense,
        balance_cents: income - expense
      }
    end
  end

  def load_category_summary
    @category_summary = @transactions
                          .where(kind: "expense")
                          .where(
                            occurred_on: @reference_date.beginning_of_year..
                                         @reference_date.end_of_year
                          )
                          .where.not(category_id: nil)
                          .joins(:category)
                          .group("categories.name")
                          .sum(:amount_cents)
                          .sort_by { |_name, amount| -amount }
  end
end
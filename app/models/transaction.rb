class Transaction < ApplicationRecord
  KINDS = %w[income expense].freeze

  belongs_to :user
  belongs_to :category, optional: true
  belongs_to :credit_card, optional: true

  validates :description, presence: true, length: { maximum: 120 }

  validates :amount_cents,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than: 0
            }

  validates :kind,
            presence: true,
            inclusion: { in: KINDS }

  validates :occurred_on, presence: true

  validates :installments_count,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 1,
              less_than_or_equal_to: 36
            }

  validate :category_belongs_to_user
  validate :credit_card_belongs_to_user

  scope :recent_first, -> { order(occurred_on: :desc, created_at: :desc) }
  scope :incomes, -> { where(kind: "income") }
  scope :expenses, -> { where(kind: "expense") }

  def income?
    kind == "income"
  end

  def expense?
    kind == "expense"
  end

  def formatted_amount
    ApplicationController.helpers.number_to_currency(
      amount_cents.to_i / 100.0,
      unit: "R$ ",
      separator: ",",
      delimiter: "."
    )
  end

  private

  def category_belongs_to_user
    return if category.blank? || category.user_id == user_id

    errors.add(:category, "não pertence ao usuário")
  end

  def credit_card_belongs_to_user
    return if credit_card.blank? || credit_card.user_id == user_id

    errors.add(:credit_card, "não pertence ao usuário")
  end
end
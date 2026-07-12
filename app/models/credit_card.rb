class CreditCard < ApplicationRecord
  belongs_to :user

  has_many :transactions, dependent: :nullify

  validates :name, presence: true, length: { maximum: 60 }

  validates :limit_cents,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 0
            }

  validates :closing_day,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 1,
              less_than_or_equal_to: 31
            }

  validates :due_day,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: 1,
              less_than_or_equal_to: 31
            }

  def formatted_limit
    ApplicationController.helpers.number_to_currency(
      limit_cents.to_i / 100.0,
      unit: "R$ ",
      separator: ",",
      delimiter: "."
    )
  end
end
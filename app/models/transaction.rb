class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true
  belongs_to :credit_card, optional: true

  validates :amount_cents, presence: true, numericality: { greater_than: 0 }
  validates :kind, presence: true, inclusion: { in: %w[income expense] }
  validates :description, presence: true
  validates :occurred_on, presence: true
end
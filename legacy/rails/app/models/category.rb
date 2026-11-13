class Category < ApplicationRecord
  belongs_to :user
  has_many :transactions, dependent: :nullify

  validates :name, presence: true, length: { maximum: 60 }
  validates :icon, length: { maximum: 32 }
  validates :color, format: { with: /\A#[0-9a-f]{6}\z/i }, allow_blank: true
end

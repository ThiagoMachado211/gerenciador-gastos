class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :lockable

  validate :strong_admin_password, if: -> { admin? && password.present? }
  validates :name, length: { maximum: 100 }

  has_many :categories, dependent: :destroy
  has_many :credit_cards, dependent: :destroy
  has_many :transactions, dependent: :destroy
  private

  def strong_admin_password
    unless password.length >= 32 && password.match?(/[a-z]/) && password.match?(/[A-Z]/) && password.match?(/[0-9]/) && password.match?(/[^a-zA-Z0-9]/)
      errors.add(:password, "de administrador deve ter pelo menos 32 caracteres, com maiúsculas, minúsculas, números e símbolos")
    end
  end
end

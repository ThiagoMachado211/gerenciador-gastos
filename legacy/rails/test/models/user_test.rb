require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "new and reset passwords require at least twelve characters" do
    user = users(:one)
    user.password = user.password_confirmation = "Short123!"
    assert_not user.valid?
    assert user.errors[:password].any?
    user.password = user.password_confirmation = "RegularPassword123!"
    assert user.valid?
  end

  test "rejects oversized display names" do
    user = users(:one)
    user.name = "a" * 101
    assert_not user.valid?
  end
  test "account deletion removes all owned financial records" do
    user = users(:one)
    category_id = categories(:one).id
    card_id = credit_cards(:one).id
    transaction_id = transactions(:one).id
    user.destroy!
    assert_not Category.exists?(category_id)
    assert_not CreditCard.exists?(card_id)
    assert_not Transaction.exists?(transaction_id)
    assert User.exists?(users(:two).id)
  end
end

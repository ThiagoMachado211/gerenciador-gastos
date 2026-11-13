require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  test "rejects resources owned by another user" do
    transaction = transactions(:one)
    transaction.category = categories(:two)
    transaction.credit_card = credit_cards(:two)
    assert_not transaction.valid?
    assert transaction.errors[:category].any?
    assert transaction.errors[:credit_card].any?
  end

  test "allows a transaction without a category or card" do
    transaction = transactions(:one)
    transaction.category = nil
    transaction.credit_card = nil
    assert transaction.valid?
  end

  test "rejects nonpositive amounts" do
    transaction = transactions(:one)
    transaction.amount_cents = 0
    assert_not transaction.valid?
  end

  test "accepts the largest database amount and rejects larger values" do
    transaction = transactions(:one)
    transaction.amount_cents = 2_147_483_647
    assert transaction.valid?
    transaction.amount_cents = 2_147_483_648
    assert_not transaction.valid?
  end
end

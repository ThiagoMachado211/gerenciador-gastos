require "test_helper"

class CreditCardTest < ActiveSupport::TestCase
  test "deleting a card preserves its transactions" do
    transaction = transactions(:one)
    assert_no_difference "Transaction.count" do
      credit_cards(:one).destroy!
    end
    assert_nil transaction.reload.credit_card_id
  end

  test "rejects invalid closing and due days" do
    card = credit_cards(:one)
    card.closing_day = 0
    card.due_day = 32
    assert_not card.valid?
    assert card.errors[:closing_day].any?
    assert card.errors[:due_day].any?
  end

  test "rejects limits outside the database range" do
    card = credit_cards(:one)
    card.limit_cents = 2_147_483_648
    assert_not card.valid?
    assert card.errors[:limit_cents].any?
  end
end

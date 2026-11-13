require "test_helper"

class Users::CreditCardsControllerTest < ActionDispatch::IntegrationTest
  setup { post user_session_url, params: { user: { email: users(:one).email, password: "Password123!" } } }

  test "enforces free card limit" do
    assert_no_difference "CreditCard.count" do
      post users_credit_cards_url, params: {
        credit_card: { name: "Extra", limit_cents: 10000, closing_day: 10, due_day: 20 }
      }
    end
    assert_redirected_to users_credit_cards_url
  end

  test "creates first card for the signed in user" do
    credit_cards(:one).destroy!
    assert_difference "users(:one).credit_cards.count", 1 do
      post users_credit_cards_url, params: {
        credit_card: { name: "Principal", limit_cents: 10000, closing_day: 10, due_day: 20 }
      }
    end
    assert_redirected_to users_credit_cards_url
  end

  test "cannot change or delete another users card" do
    card = credit_cards(:two)
    patch users_credit_card_url(card), params: { credit_card: { name: "Alterado" } }
    assert_response :not_found
    assert_equal "MyString", card.reload.name
    assert_no_difference "CreditCard.count" do
      delete users_credit_card_url(card)
    end
    assert_response :not_found
  end
end

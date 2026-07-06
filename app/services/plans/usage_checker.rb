module Plans
  class UsageChecker
    FREE_CATEGORY_LIMIT = 4
    FREE_CREDIT_CARD_LIMIT = 1

    def initialize(user)
      @user = user
    end

    def can_create_category?
      paid_user? || @user.categories.count < FREE_CATEGORY_LIMIT
    end

    def can_create_credit_card?
      paid_user? || @user.credit_cards.count < FREE_CREDIT_CARD_LIMIT
    end

    private

    def paid_user?
      return false unless @user.respond_to?(:subscription)

      @user.subscription&.plan&.name == "paid"
    end
  end
end
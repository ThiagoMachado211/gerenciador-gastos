require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "deleting a category preserves its transactions" do
    transaction = transactions(:one)
    assert_no_difference "Transaction.count" do
      categories(:one).destroy!
    end
    assert_nil transaction.reload.category_id
  end
end

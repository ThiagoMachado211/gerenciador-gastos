require "test_helper"

class Users::CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup { post user_session_url, params: { user: { email: users(:one).email, password: "Password123!" } } }

  test "creates category for signed in user" do
    assert_difference "users(:one).categories.count", 1 do
      post users_categories_url, params: { category: { name: "Moradia" } }
    end
    assert_redirected_to users_categories_url
  end

  test "enforces free category limit" do
    3.times { |i| users(:one).categories.create!(name: "Categoria #{i}") }
    assert_no_difference "Category.count" do
      post users_categories_url, params: { category: { name: "Extra" } }
    end
    assert_redirected_to users_categories_url
  end

  test "cannot update or delete another users category" do
    category = categories(:two)
    patch users_category_url(category), params: { category: { name: "Alterada" } }
    assert_response :not_found
    assert_equal "MyString", category.reload.name
    assert_no_difference "Category.count" do
      delete users_category_url(category)
    end
    assert_response :not_found
  end

  test "deletes used category without losing financial history" do
    assert_difference "Category.count", -1 do
      assert_no_difference "Transaction.count" do
        delete users_category_url(categories(:one))
      end
    end
    assert_redirected_to users_categories_url
    assert_nil transactions(:one).reload.category_id
  end
end

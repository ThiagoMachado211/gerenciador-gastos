require "application_system_test_case"

class AccountSecurityTest < ApplicationSystemTestCase
  test "login renders charts with CSP and logout protects financial pages" do
    visit new_user_session_path
    fill_in "user_email", with: users(:one).email
    fill_in "user_password", with: "Password123!"
    find("input[type=submit]").click
    assert_current_path users_dashboard_path
    assert_selector "canvas[data-dashboard-charts-target=monthly]"
    assert_selector "canvas[data-dashboard-charts-target=monthly][style]"
    click_link "Sair"
    assert_current_path root_path
    visit users_transactions_path
    assert_current_path new_user_session_path
  end
end

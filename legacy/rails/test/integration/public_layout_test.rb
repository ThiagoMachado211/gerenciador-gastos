require "test_helper"

class PublicLayoutTest < ActionDispatch::IntegrationTest
  test "landing navigation has all target sections and shared theme" do
    get root_url
    assert_response :success
    assert_select "html[lang=pt-BR]"
    %w[inicio features como-funciona precos].each { |id| assert_select "##{id}", count: 1 }
    assert_select "footer"
    assert_select "link[href*='theme']"
    assert_not_includes response.body, "gastos parcelados"
  end

  test "registration fields and error feedback use authentication styles" do
    get new_user_registration_url
    assert_select "input#user_email.auth-input"
    assert_select "input#user_password_confirmation.auth-input"
    assert_select ".auth-tab[aria-current=page]", text: "Criar conta"
    post user_registration_url, params: { user: { email: "invalid", password: "a", password_confirmation: "b" } }
    assert_response :unprocessable_content
    assert_select ".form-errors[role=alert]"
  end

  test "invalid login displays a visible error message" do
    post user_session_url, params: { user: { email: users(:one).email, password: "wrong" } }
    follow_redirect! if response.redirect?
    assert_select ".flash-message--error[role=alert]"
  end

  test "password recovery uses the authentication layout" do
    get new_user_password_url
    assert_response :success
    assert_select "body.auth-body"
    assert_select "input#user_email.auth-input"
    assert_select "h1", text: "Recuperar senha"
  end
end

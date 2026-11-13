class Users::PasswordsController < Devise::PasswordsController
  include AuthenticationRateLimited
  before_action only: %i[create update] do
    enforce_authentication_limits(ip_limit: 10, email_limit: 3, period: 15.minutes)
  end

  layout "authentication"
end

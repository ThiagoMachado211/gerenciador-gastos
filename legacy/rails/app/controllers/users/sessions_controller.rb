class Users::SessionsController < Devise::SessionsController
  include AuthenticationRateLimited
  before_action only: :create do
    enforce_authentication_limits(ip_limit: 30, email_limit: 10, period: 15.minutes)
  end

  layout "authentication"
end

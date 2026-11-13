class Users::RegistrationsController < Devise::RegistrationsController
  include AuthenticationRateLimited
  before_action only: :create do
    enforce_authentication_limits(ip_limit: 5, period: 1.hour)
  end

  layout "authentication"
end

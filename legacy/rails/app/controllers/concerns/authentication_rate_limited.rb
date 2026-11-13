module AuthenticationRateLimited
  extend ActiveSupport::Concern

  included do
    before_action { response.headers["Cache-Control"] = "no-store" }
  end

  private

  def enforce_authentication_limits(ip_limit:, period:, email_limit: nil)
    identities = [ [ "ip", request.remote_ip, ip_limit ] ]
    user_params = params[:user]
    email = user_params[:email] if user_params.is_a?(ActionController::Parameters)
    if email_limit && email.is_a?(String) && email.present?
      identities << [ "email", email.strip.downcase, email_limit ]
    end

    identities.each do |kind, identity, limit|
      next if RequestRateLimit.allow_request?(
        scope: "#{controller_path}:#{action_name}:#{kind}", identity: identity, limit: limit, period: period
      )

      response.headers["Retry-After"] = period.to_i.to_s
      head :too_many_requests
      break
    end
  end
end

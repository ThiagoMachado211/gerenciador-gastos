# Asset compilation does not connect to production services.
if Rails.env.production? && ENV["SECRET_KEY_BASE_DUMMY"].blank?
  required = %w[APP_HOST DATABASE_URL MAIL_FROM SMTP_ADDRESS SMTP_USERNAME SMTP_PASSWORD]
  missing = required.select { |name| ENV[name].blank? }
  raise "Missing production environment variables: #{missing.join(", ")}" if missing.any?

  unless ENV["APP_HOST"].match?(/\A[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?\z/i)
    raise "APP_HOST must contain a hostname without protocol, port or path"
  end
end

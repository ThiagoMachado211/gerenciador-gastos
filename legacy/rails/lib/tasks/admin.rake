require "json"

namespace :admin do
  desc "Create an administrator from environment variables or a local ignored credentials file"
  task create: :environment do
    if ENV["ADMIN_EMAIL"].present? || ENV["ADMIN_PASSWORD"].present?
      credentials = { "email" => ENV["ADMIN_EMAIL"], "password" => ENV["ADMIN_PASSWORD"] }
    else
      credentials_file = Rails.root.join(".admin/credentials.json")
      abort "Provide ADMIN_EMAIL and ADMIN_PASSWORD, or the local .admin/credentials.json file." unless credentials_file.file?
      credentials = JSON.parse(credentials_file.read)
    end

    email = credentials.fetch("email", "").to_s.strip.downcase
    password = credentials.fetch("password", "").to_s
    abort "A valid admin email is required." unless email.match?(Devise.email_regexp)
    unless password.length.between?(32, 128) && password.match?(/[a-z]/) && password.match?(/[A-Z]/) && password.match?(/[0-9]/) && password.match?(/[^a-zA-Z0-9]/)
      abort "Admin password must have 32–128 characters with upper/lowercase letters, numbers and symbols."
    end

    # Never promote an existing public account or silently reset a password.
    abort "An account with this identifier already exists; no changes were made." if User.exists?(email: email)

    User.create!(email: email, name: "Administrador", password: password, password_confirmation: password, admin: true)
    puts "Administrator created. Sign in normally and open /admin."
  end
end

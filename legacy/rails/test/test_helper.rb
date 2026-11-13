abort "Tests must run with RAILS_ENV=test" if ENV["RAILS_ENV"] && ENV["RAILS_ENV"] != "test"
ENV["RAILS_ENV"] = "test"
require_relative "../config/environment"
abort "Tests require a dedicated database whose name ends in _test" unless Rails.env.test? && ActiveRecord::Base.connection_db_config.database.end_with?("_test")
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Keep mail delivery assertions isolated and support Windows without fork.
    parallelize(workers: 1)
    fixtures :all
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include ActionMailer::TestHelper
end

require "test_helper"
require "rake"

class AdminProvisioningTest < ActiveSupport::TestCase
  TEST_PASSWORD = "OnlyForTests-Provision-Password-123!"

  setup do
    Rails.application.load_tasks unless Rake::Task.task_defined?("admin:create")
    @previous_email = ENV["ADMIN_EMAIL"]
    @previous_password = ENV["ADMIN_PASSWORD"]
    ENV["ADMIN_EMAIL"] = "provisioned-admin@example.test"
    ENV["ADMIN_PASSWORD"] = TEST_PASSWORD
    Rake::Task["admin:create"].reenable
  end

  teardown do
    ENV["ADMIN_EMAIL"] = @previous_email
    ENV["ADMIN_PASSWORD"] = @previous_password
    Rake::Task["admin:create"].reenable
  end

  test "explicit provisioning creates a hashed administrator account" do
    assert_difference "User.count", 1 do
      capture_io { Rake::Task["admin:create"].invoke }
    end
    admin = User.find_by!(email: ENV["ADMIN_EMAIL"])
    assert admin.admin?
    assert admin.valid_password?(TEST_PASSWORD)
    assert_not_equal TEST_PASSWORD, admin.encrypted_password
  end

  test "provisioning refuses to promote an existing public account" do
    ENV["ADMIN_EMAIL"] = users(:one).email
    capture_io do
      assert_raises(SystemExit) { Rake::Task["admin:create"].invoke }
    end
    assert_not users(:one).reload.admin?
  end

  test "provisioning refuses a weak password" do
    ENV["ADMIN_PASSWORD"] = "Weak123!"
    assert_no_difference "User.count" do
      capture_io do
        assert_raises(SystemExit) { Rake::Task["admin:create"].invoke }
      end
    end
  end
end

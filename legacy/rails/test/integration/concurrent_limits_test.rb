require "test_helper"

class ConcurrentLimitsTest < ActionDispatch::IntegrationTest
  self.use_transactional_tests = false

  setup do
    @user = User.create!(email: "concurrent-#{SecureRandom.hex(8)}@example.test", password: "ConcurrentPassword123!")
  end

  teardown do
    @user.destroy!
    RequestRateLimit.delete_all
  end

  test "simultaneous category requests cannot exceed the free plan" do
    3.times { |index| @user.categories.create!(name: "Category #{index}") }
    sessions = authenticated_sessions
    responses = concurrently(sessions) do |session|
      session.post users_categories_path, params: { category: { name: "Concurrent category" } }
      session.response.status
    end
    assert_equal [ 302, 302 ], responses
    assert_equal 4, @user.categories.count
  end

  test "simultaneous card requests cannot exceed the free plan" do
    sessions = authenticated_sessions
    responses = concurrently(sessions) do |session|
      session.post users_credit_cards_path, params: { credit_card: { name: "Concurrent card", limit_cents: 100, closing_day: 1, due_day: 10 } }
      session.response.status
    end
    assert_equal [ 302, 302 ], responses
    assert_equal 1, @user.credit_cards.count
  end

  test "rate limit increments are atomic across connections" do
    results = concurrently((1..12).to_a) do |_index|
      RequestRateLimit.allow_request?(scope: "concurrent", identity: @user.id.to_s, limit: 3, period: 1.minute)
    end
    assert_equal 3, results.count(true)
  end

  private

  def authenticated_sessions
    Array.new(2) do
      session = open_session
      session.post user_session_path, params: { user: { email: @user.email, password: "ConcurrentPassword123!" } }
      assert_equal 303, session.response.status
      session
    end
  end

  def concurrently(items)
    ready = Queue.new
    start = Queue.new
    threads = items.map do |item|
      Thread.new do
        ready << true
        start.pop
        ActiveRecord::Base.connection_pool.with_connection { yield item }
      end
    end
    items.size.times { ready.pop }
    items.size.times { start << true }
    threads.map(&:value)
  end
end

require "test_helper"

class RequestRateLimitTest < ActiveSupport::TestCase
  test "limits an identity and resets after expiry without extending the window" do
    options = { scope: "test", identity: "client", limit: 2, period: 1.minute }
    assert RequestRateLimit.allow_request?(**options)
    expires_at = RequestRateLimit.first.expires_at
    travel 30.seconds do
      assert RequestRateLimit.allow_request?(**options)
      assert_not RequestRateLimit.allow_request?(**options)
      assert_in_delta expires_at.to_f, RequestRateLimit.first.expires_at.to_f, 0.001
    end
    travel 61.seconds do
      assert RequestRateLimit.allow_request?(**options)
    end
  end

  test "scopes and clients have independent limits and identifiers are not stored" do
    options = { scope: "login", identity: "private@example.test", limit: 1, period: 1.minute }
    assert RequestRateLimit.allow_request?(**options)
    assert_not RequestRateLimit.allow_request?(**options)
    assert RequestRateLimit.allow_request?(**options.merge(scope: "reset"))
    assert RequestRateLimit.allow_request?(**options.merge(identity: "another@example.test"))
    assert RequestRateLimit.pluck(:key).all? { |key| key.match?(/\A[0-9a-f]{64}\z/) }
  end
end

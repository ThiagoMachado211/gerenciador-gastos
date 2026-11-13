require "digest"

# PostgreSQL serializes the upsert, sharing limits across threads and servers.
class RequestRateLimit < ApplicationRecord
  def self.allow_request?(scope:, identity:, limit:, period:)
    now = Time.current
    key = Digest::SHA256.hexdigest([ scope, identity ].join("\0"))
    where("expires_at < ?", now - 1.day).delete_all

    connection_pool.with_connection do |connection|
      sql = <<~SQL
        INSERT INTO request_rate_limits (key, requests_count, expires_at)
        VALUES ($1, 1, $2)
        ON CONFLICT (key) DO UPDATE SET
          requests_count = CASE WHEN request_rate_limits.expires_at <= $3 THEN 1
            ELSE LEAST(request_rate_limits.requests_count, 2147483646) + 1 END,
          expires_at = CASE WHEN request_rate_limits.expires_at <= $3 THEN EXCLUDED.expires_at
            ELSE request_rate_limits.expires_at END
        RETURNING requests_count
      SQL
      binds = [
        ActiveRecord::Relation::QueryAttribute.new("key", key, type_for_attribute("key")),
        ActiveRecord::Relation::QueryAttribute.new("expires_at", now + period, type_for_attribute("expires_at")),
        ActiveRecord::Relation::QueryAttribute.new("now", now, type_for_attribute("expires_at"))
      ]
      result = connection.exec_query(sql, "Authentication rate limit", binds)
      result.first.fetch("requests_count") <= limit
    end
  end
end

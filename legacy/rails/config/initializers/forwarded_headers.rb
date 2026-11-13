# The trusted reverse proxy must append the real client to X-Forwarded-For.
# Ignore client-supplied RFC 7239 Forwarded headers for IP, host and scheme.
Rack::Request.forwarded_priority = [ :x_forwarded ]

require 'rack/rate_limiter/version'

module Rack
  class RateLimiter
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, response = @app.call(env)
      headers['X-RateLimit-Limit'] = 60

      [status, headers, response]
    end
  end
end

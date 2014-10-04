require 'rack/rate_limiter/version'

module Rack
  class RateLimiter
    DEFAULT_RATE_LIMIT = 60

    def initialize(app, options ={})
      @app = app

      @rate_limit         = options[:limit] || DEFAULT_RATE_LIMIT
      @remaining_requests = @rate_limit
    end

    def call(env)
      status, headers, response        = @app.call(env)
      headers['X-RateLimit-Limit']     = @rate_limit
      headers['X-RateLimit-Remaining'] = decrease_remaining_request

      [status, headers, response]
    end

    private

    def decrease_remaining_request
      @rate_limit -= 1 unless @rate_limit.zero?
      @rate_limit
    end
  end
end

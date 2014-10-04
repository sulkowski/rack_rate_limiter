require 'rack/rate_limiter/version'

module Rack
  class TooManyRequests < RangeError; end

  class RateLimiter
    DEFAULT_RATE_LIMIT = 60

    def initialize(app, options ={})
      @app = app

      @rate_limit         = options[:limit] || DEFAULT_RATE_LIMIT
      @remaining_requests = @rate_limit
    end

    def call(env)
      decrease_remaining_requests
      status, headers, response        = @app.call(env)
      headers['X-RateLimit-Limit']     = @rate_limit
      headers['X-RateLimit-Remaining'] = @remaining_requests
      [status, headers, response]
    rescue TooManyRequests
      [403, { 'Content-Type' => 'text/plain' }, ['Too many requests']]
    end

    private

    def decrease_remaining_requests
      raise TooManyRequests if @remaining_requests.zero?
      @remaining_requests -= 1
      @remaining_requests
    end
  end
end

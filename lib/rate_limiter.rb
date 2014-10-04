require 'rack/rate_limiter/version'

module Rack
  class RateLimiter
    def initialize(app, options ={})
      @app        = app
      @rate_limit = options[:limit] || 60
    end

    def call(env)
      status, headers, response    = @app.call(env)
      headers['X-RateLimit-Limit'] = @rate_limit

      [status, headers, response]
    end
  end
end

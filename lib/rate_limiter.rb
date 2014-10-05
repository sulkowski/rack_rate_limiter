require 'rack/rate_limiter/version'

module Rack
  class TooManyRequests < RangeError; end

  class RateLimiter
    DEFAULT_RATE_LIMIT = 60

    def initialize(app, options ={})
      @app = app

      @rate_limit = options[:limit] || DEFAULT_RATE_LIMIT
      @users      = Hash.new { |hash, key| hash[key] = { remaining_requests: @rate_limit,
                                                         reset_time: Time.now.to_i + 60*60 } }
    end

    def call(env)
      user = update_user_attributes(@users[env['REMOTE_ADDR']])

      status, headers, response        = @app.call(env)
      headers['X-RateLimit-Limit']     = @rate_limit
      headers['X-RateLimit-Remaining'] = user[:remaining_requests]
      headers['X-RateLimit-Reset']     = user[:reset_time]

      [status, headers, response]
    rescue TooManyRequests
      [403, { 'Content-Type' => 'text/plain' }, ['Too many requests']]
    end

    private

    def decrease_remaining_requests(user)
      raise TooManyRequests if user[:remaining_requests].zero?
      user[:remaining_requests] -= 1

      user
    end

    def update_reset_time(user)
      user[:reset_time] = Time.now.to_i + 60*60 if user[:reset_time] <= Time.now.to_i

      user
    end

    def update_user_attributes(user)
      update_reset_time(user)
      decrease_remaining_requests(user)

      user
    end
  end
end

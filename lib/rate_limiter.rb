require 'rack/rate_limiter/version'
require 'rack'

module Rack
  class TooManyRequests < RangeError; end

  class RateLimiter
    DEFAULT_RATE_LIMIT = 60

    def initialize(app, options ={}, &customization_block)
      @app = app

      @rate_limit = options[:limit] || DEFAULT_RATE_LIMIT
      @users      = Hash.new { |hash, key| hash[key] = { remaining_requests: @rate_limit,
                                                         reset_time: time_after_an_hour(Time.now).to_i } }
      @customization_block = customization_block
    end

    def call(env)
      status, headers, response = @app.call(env)

      if user_id = get_user_id(env)
        user = update_user_attributes(@users[user_id])

        headers['X-RateLimit-Limit']     = @rate_limit
        headers['X-RateLimit-Remaining'] = user[:remaining_requests]
        headers['X-RateLimit-Reset']     = user[:reset_time]
      end

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
      user[:reset_time] = time_after_an_hour(Time.now).to_i if user[:reset_time] <= Time.now.to_i

      user
    end

    def get_user_id(env)
      if @customization_block
        user_id = @customization_block.call(env)
      else
        user_id = env['REMOTE_ADDR']
      end

      user_id
    end

    def update_user_attributes(user)
      update_reset_time(user)
      decrease_remaining_requests(user)

      user
    end

    def time_after_an_hour(time)
      Time.now + 60*60
    end
  end
end

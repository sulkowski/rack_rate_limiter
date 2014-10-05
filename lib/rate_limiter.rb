require 'rack/rate_limiter/version'
require 'rack'

module Rack
  class TooManyRequests < RangeError; end

  class RateLimiter
    class InternalMemory
      def initialize
        @memory = Hash.new
      end

      def get(attribute)
        @memory[attribute.to_s]
      end

      def set(attribute, value)
        @memory[attribute.to_s] = value
      end
    end

    DEFAULT_RATE_LIMIT = 60

    def initialize(app, options ={}, &customization_block)
      @memory = set_memory(options[:memory])

      @memory.set('app', app)
      @memory.set('rate_limit', options[:limit] || DEFAULT_RATE_LIMIT)
      @memory.set('users', Hash.new { |hash, key| hash[key] = { remaining_requests: @memory.get('rate_limit'),
                                                                reset_time: time_after_an_hour(Time.now).to_i } } )
      @memory.set('customization_block', customization_block)
    end

    def call(env)
      status, headers, response = @memory.get('app').call(env)

      if user_id = get_user_id(env)
        user = update_user_attributes(@memory.get('users')[user_id])

        headers['X-RateLimit-Limit']     = @memory.get('rate_limit')
        headers['X-RateLimit-Remaining'] = user[:remaining_requests]
        headers['X-RateLimit-Reset']     = user[:reset_time]
      end

      [status, headers, response]
    rescue TooManyRequests
      [403, { 'Content-Type' => 'text/plain' }, ['Too many requests']]
    end

    private

    def set_memory(memory)
      @memory = memory.nil? ? InternalMemory.new : memory
    end

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
      if  @memory.get('customization_block')
        user_id = @memory.get('customization_block').call(env)
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

require 'rack/rate_limiter/version'
require 'rack'

module Rack
  class TooManyRequests < RangeError; end

  class RateLimiter
    class InternalDataStorage
      def initialize
        @memory = { }
      end

      def get(key)
        @memory[key]
      end

      def set(key, value)
        @memory[key] = value
      end
    end

    DEFAULT_RATE_LIMIT = 60
    DEFAULT_CONFIGURATION_BLOCK = Proc.new { |env| env['REMOTE_ADDR'] }

    def initialize(app, options ={}, &configuration_block)
      @memory = initialize_memory(options[:memory])

      @app = app
      @rate_limit = options[:limit] || DEFAULT_RATE_LIMIT
      @configuration_block = configuration_block || DEFAULT_CONFIGURATION_BLOCK
    end

    def call(env)
      status, headers, response = @app.call(env)

      if client_id = evaluate_client_id(env)
        client = update_client_attributes(find_or_create_client(client_id))

        headers['X-RateLimit-Limit']     = @rate_limit
        headers['X-RateLimit-Remaining'] = client[:remaining_requests]
        headers['X-RateLimit-Reset']     = client[:reset_at]
      end

      [status, headers, response]
    rescue TooManyRequests
      [429, { 'Content-Type' => 'text/plain' }, 'Too many requests']
    end

    private

    def initialize_memory(memory)
      @memory = memory.nil? ? InternalDataStorage.new : memory
    end

    def update_client_attributes(client)
      update_reset_at(client)
      decrease_remaining_requests(client)
      set_client(client)

      client
    end

    def update_reset_at(client)
      client[:reset_at] = timestamp_for(Time.now + 60 * 60) if exceeded_reset_at?(client)

      client
    end

    def decrease_remaining_requests(client)
      raise TooManyRequests if remaining_requests?(client)
      client[:remaining_requests] -= 1

      client
    end

    def exceeded_reset_at?(client)
      Time.now.to_i > client[:reset_at]
    end

    def remaining_requests?(client)
      client[:remaining_requests].zero?
    end

    def evaluate_client_id(env)
      @configuration_block.call(env)
    end

    def find_or_create_client(client_id)
      unless client = get_client(client_id)
        client = { id: client_id,
                   remaining_requests: @rate_limit,
                   reset_at: timestamp_for(Time.now + 60 * 60)
                 }
        set_client(client)
      end

      client
    end

    def set_client(client)
      @memory.set("client-#{client[:id]}", client)
    end

    def get_client(client_id)
      @memory.get("client-#{client_id}")
    end

    def timestamp_for(time)
     time.to_i
    end
  end
end

require 'rack/test'
require 'rate_limiter'
require 'timecop'

RSpec.configure do |config|
  config.include Rack::Test::Methods
end

def at_time(time, &block)
  Timecop.travel(Time.parse(time), &block)
end

def timestamp_for(time)
  Time.parse(time).to_i
end

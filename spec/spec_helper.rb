require 'rack/test'
require 'rate_limiter'
require 'timecop'

RSpec.configure do |config|
  config.include Rack::Test::Methods
end

def time_after_an_hour(time)
  time + 60*60
end

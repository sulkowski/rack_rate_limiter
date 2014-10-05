require 'rack/test'
require 'rate_limiter'
require 'timecop'

RSpec.configure do |config|
  config.include Rack::Test::Methods
end

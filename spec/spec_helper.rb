require 'rack/test'
require 'rate_limiter'

RSpec.configure do |config|
  config.include Rack::Test::Methods
end

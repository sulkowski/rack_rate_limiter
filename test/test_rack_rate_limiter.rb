require 'minitest/autorun'
require 'rack/test'
require 'rate_limiter'

class TestRakeLimiter < MiniTest::Test
  include Rack::Test::Methods

  def app
    Rack::RateLimiter.new(lambda { |env| [200, {}, ''] })
  end

  def test_successful_response
    get '/'
    assert last_response.ok?
  end

  def test_existence_and_value_of_x_rate_limit_in_the_header
    get '/'
    assert last_response.header.include?('X-RateLimit-Limit')
    assert_equal 60, last_response.header['X-RateLimit-Limit']
  end
end

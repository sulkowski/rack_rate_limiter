require 'minitest/autorun'
require 'rack/test'
require 'rate_limiter'

class TestRateLimiter < MiniTest::Test
  include Rack::Test::Methods

  def setup
    @rate_limiter_options = {}
  end

  def app
    Rack::RateLimiter.new(lambda { |env| [200, {}, ''] }, @rate_limiter_options)
  end

  def test_successful_response
    get '/'
    assert last_response.ok?
  end

  def test_presence_of_x_rate_limit_in_the_header
    get '/'
    assert last_response.header.include?('X-RateLimit-Limit')
    assert_equal 60, last_response.header['X-RateLimit-Limit']
  end

  def test_default_value_of_x_rate_limit_in_the_header
    get '/'
    assert_equal 60, last_response.header['X-RateLimit-Limit']
  end

  def test_custom_value_of_x_rate_limit_in_the_header
    @rate_limiter_options = { limit: 40 }
    get '/'
    assert_equal 40, last_response.header['X-RateLimit-Limit']
  end
end

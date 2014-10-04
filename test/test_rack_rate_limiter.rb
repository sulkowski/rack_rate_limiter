require 'minitest/autorun'
require 'rack/test'

class TestRakeLimiter < MiniTest::Test
  include Rack::Test::Methods

  def app
    lambda { |env| [200, {}, ''] }
  end

  def test_successful_response
    get '/'
    assert last_response.ok?
  end
end

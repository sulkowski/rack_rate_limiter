require 'spec_helper'

describe Rack::RateLimiter do
  before(:each) do
    @rate_limiter_options = {}
  end

  def app
    Rack::RateLimiter.new(lambda { |env| [200, {}, ''] }, @rate_limiter_options)
  end

  it 'test_successful_response' do
    get '/'
    expect(last_response.ok?).to be_truthy
  end

  describe 'X-RateLimit-Limit' do
    it 'has the X-RateLimit-Limit in the header' do
      get '/'
      expect(last_response.header).to include('X-RateLimit-Limit')
    end

    it 'has a default value of the `X-RateLimit-Limit` in the header' do
      get '/'
      expect(last_response.header['X-RateLimit-Limit']).to eq(60)
    end

    it 'has a custom value of the `X-RateLimit-Limit` in the header' do
      @rate_limiter_options = { limit: 40 }
      get '/'
      expect(last_response.header['X-RateLimit-Limit']).to eq(40)
    end
  end
end

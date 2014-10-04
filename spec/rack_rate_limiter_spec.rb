require 'spec_helper'

describe Rack::RateLimiter do
  before(:each) do
    @rate_limiter_options = {}
  end

  def app
    Rack::RateLimiter.new(lambda { |env| [200, {}, ''] }, @rate_limiter_options)
  end

  it 'returns a successful response' do
    get '/'
    expect(last_response.ok?).to be_truthy
  end

  describe 'X-RateLimit-Limit' do
    describe 'default value of the `X-RateLimit-Limit`' do
      before(:each) { get '/' }
      it 'has the `X-RateLimit-Limit` in the header' do
        expect(last_response.header).to include('X-RateLimit-Limit')
      end

      it 'has a default value of the `X-RateLimit-Limit`' do
        expect(last_response.header['X-RateLimit-Limit']).to eq(60)
      end
    end

    describe 'custom value of `X-RateLimit-Limit`' do
      before(:each) do
        @rate_limiter_options = { limit: 40 }
        get '/'
      end

      it 'has a custom value of the `X-RateLimit-Limit`' do
        expect(last_response.header['X-RateLimit-Limit']).to eq(40)
      end
    end
  end

  describe 'X-RateLimit-Remaining' do
    it 'has the `X-RateLimit-Remaining` in the header' do
      get '/'
      expect(last_response.header).to include('X-RateLimit-Remaining')
    end

    it 'deacreases the `X-RateLimit-Remaining` with each request' do
      (1..20).each do |request_number|
        get '/'
        expect(last_response.header['X-RateLimit-Remaining']).to eq(60 - request_number)
      end
      expect(last_response.header['X-RateLimit-Remaining']).to eq(40)
    end

    it 'returns 403 `X-RateLimit-Remaining` after exceeding the limit of requests' do
      60.times { get '/' }
      expect(last_response.header['X-RateLimit-Remaining']).to eq(0)

      get '/'
      expect(last_response.status).to eq(403)
      expect(last_response.body).to eq('Too many requests')
    end
  end
end

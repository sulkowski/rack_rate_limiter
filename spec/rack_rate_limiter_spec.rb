require 'spec_helper'

describe Rack::RateLimiter do
  let(:rate_limiter_options) { {} }
  let(:rate_limiter_customization_block) {}

  def app
    Rack::RateLimiter.new(lambda { |env| [200, {}, ''] }, rate_limiter_options, &rate_limiter_customization_block)
  end

  it 'returns a successful response' do
    get '/'
    expect(last_response).to be_ok
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
      let(:rate_limiter_options) { { limit: 40 } }

      it 'has a custom value of the `X-RateLimit-Limit`' do
        get '/'
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

    it 'returns 429 `X-RateLimit-Remaining` after exceeding the limit of requests' do
      60.times { get '/' }
      expect(last_response.header['X-RateLimit-Remaining']).to eq(0)

      get '/'
      expect(last_response.status).to eq(429)
      expect(last_response.body).to eq('Too many requests')
    end
  end

  describe 'X-RateLimit-Reset' do
    it 'has the `X-RateLimit-Reset` in the header' do
      get '/'
      expect(last_response.header).to include('X-RateLimit-Reset')
    end

    it 'sets the value of the `X-RateLimit-Reset` to the time of the first request' do
      at_time('2:14') { get '/' }

      at_time '2:33' do
        3.times { get '/' }
        expect(last_response.header['X-RateLimit-Reset']).to eq(timestamp_for('3:14'))
      end
    end

    it 'resets the `X-RateLimit-Reset` value after an hour since the first request' do
      at_time('3:33') { get '/' }

      at_time '4:37' do
        get '/'
        expect(last_response.header['X-RateLimit-Reset']).to eq(timestamp_for('5:37'))
      end
    end
  end

  describe 'requests from clients with different IPs' do
    let(:ip_client_1) { '172.16.0.1' }
    let(:ip_client_2) { '172.16.0.2' }

    describe 'X-RateLimit-Remaining' do
      it 'has different values of the the `X-RateLimit-Remaining` fo each client' do
        3.times { get '/', {}, 'REMOTE_ADDR' => ip_client_1 }
        expect(last_response.header['X-RateLimit-Remaining']).to eq(57)

        7.times { get '/', {}, 'REMOTE_ADDR' => ip_client_2 }
        expect(last_response.header['X-RateLimit-Remaining']).to eq(53)
      end
    end

    describe 'X-RateLimit-Reset' do
      it 'has different values of the `X-RateLimit-Reset` for each client' do
        at_time '2:03' do
          get '/', {}, 'REMOTE_ADDR' => ip_client_1
          expect(last_response.header['X-RateLimit-Reset']).to eq(timestamp_for('3:03'))
        end

        at_time '3:19' do
          get '/', {}, 'REMOTE_ADDR' => ip_client_2
          expect(last_response.header['X-RateLimit-Reset']).to eq(timestamp_for('4:19'))
        end
      end
    end
  end

  describe 'custom client detection' do
    describe 'with an additional block' do
      let(:rate_limiter_customization_block) { Proc.new { |env| Rack::Request.new(env).params['API_TOKEN'] } }

      it 'identifies clients by the token' do
        get '/', { 'API_TOKEN' => 'ighVrvNmkLvWmjlFUZHzYQ' }, 'REMOTE_ADDR' => '172.16.1.1'
        get '/', { 'API_TOKEN' => 'ighVrvNmkLvWmjlFUZHzYQ' }, 'REMOTE_ADDR' => '172.16.1.2'
        expect(last_response.header['X-RateLimit-Remaining']).to eq(58)
      end

      it 'does not include X-RateLimit-Limit, X-RateLimit-Remaining and X-RateLimit-Reset if the block returns nil' do
        get '/'
        expect(last_response.header).not_to include('X-RateLimit-Limit')
        expect(last_response.header).not_to include('X-RateLimit-Remaining')
        expect(last_response.header).not_to include('X-RateLimit-Reset')
      end
    end

    describe 'without an additional block' do
      it 'identifies clients by their address IP' do
        2.times { get '/', {}, 'REMOTE_ADDR' => '172.16.1.1' }
        expect(last_response.header['X-RateLimit-Remaining']).to eq(58)

        5.times { get '/', {}, 'REMOTE_ADDR' => '172.16.1.2' }
        expect(last_response.header['X-RateLimit-Remaining']).to eq(55)
      end
    end
  end

  describe 'custom data storage' do
    let(:external_memory) { double }
    let(:rate_limiter_options) { { memory: external_memory } }

    it 'stores all data in the external data storage' do
      expect(external_memory).to receive(:get)
      expect(external_memory).to receive(:set).twice

      get '/'
    end
  end
end

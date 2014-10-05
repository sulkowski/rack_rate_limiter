require 'spec_helper'

describe Rack::RateLimiter do
  let(:rate_limiter_options) { {} }
  let(:rake_limiter_customization_block) {}

  def app
    Rack::RateLimiter.new(lambda { |env| [200, {}, ''] }, rate_limiter_options, &rake_limiter_customization_block)
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
      let(:rate_limiter_options) { { limit: 40 } }

      before(:each) do
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

  describe 'X-RateLimit-Reset' do
    let(:current_time) { Time.now }

    before(:each) do
      Timecop.freeze(current_time)
      get '/'
      Timecop.return
    end

    after(:each) { Timecop.return }

    it 'has the `X-RateLimit-Reset` in the header' do
      expect(last_response.header).to include('X-RateLimit-Reset')
    end

    it 'sets the value of the `X-RateLimit-Reset` to the time of the first request' do
      expect(last_response.header['X-RateLimit-Reset']).to eq(time_after_an_hour(current_time).to_i)
    end

    it 'doesn`t change the `X-RateLimit-Reset` value in succeeding requests' do
      5.times { get '/' }
      expect(last_response.header['X-RateLimit-Reset']).to eq(time_after_an_hour(current_time).to_i)
    end

    it 'resets the `X-RateLimit-Reset` value after an hour since the first request' do
      new_current_time = time_after_an_hour(current_time) + 60

      Timecop.freeze(new_current_time)
      get '/'
      expect(last_response.header['X-RateLimit-Reset']).to eq(time_after_an_hour(new_current_time).to_i)
    end
  end

  describe 'requests from users with different IPs' do
    let(:ip_user_1) { '172.16.0.1' }
    let(:ip_user_2) { '172.16.0.2' }

    describe 'X-RateLimit-Remaining' do
      it 'has different values of the the `X-RateLimit-Remaining` fo each user' do
        3.times { get '/', {}, 'REMOTE_ADDR' => ip_user_1 }
        expect(last_response.header['X-RateLimit-Remaining']).to eq(57)

        7.times { get '/', {}, 'REMOTE_ADDR' => ip_user_2 }
        expect(last_response.header['X-RateLimit-Remaining']).to eq(53)
      end
    end

    describe 'X-RateLimit-Reset' do
      let(:current_time_user_1) { Time.now }
      let(:current_time_user_2) { Time.now + 15*60 }

      after(:each) { Timecop.return }

      it 'has different values of the `X-RateLimit-Reset` for each user' do
        Timecop.freeze(current_time_user_1)
        get '/', {}, 'REMOTE_ADDR' => ip_user_1
        expect(last_response.header['X-RateLimit-Reset']).to eq(time_after_an_hour(current_time_user_1).to_i)

        Timecop.freeze(current_time_user_2)
        get '/', {}, 'REMOTE_ADDR' => ip_user_2
        expect(last_response.header['X-RateLimit-Reset']).to eq(time_after_an_hour(current_time_user_2).to_i)
      end
    end
  end

  describe 'custom user detection' do
    describe 'with an additional block' do
      let(:rake_limiter_customization_block) { Proc.new { |env| Rack::Request.new(env).params['API_TOKEN'] } }

      it 'identifies users by the token' do
        get '/', { 'API_TOKEN' => 'ighVrvNmkLvWmjlFUZHzYQ' }, 'REMOTE_ADDR' => '172.16.1.1'
        get '/', { 'API_TOKEN' => 'ighVrvNmkLvWmjlFUZHzYQ' }, 'REMOTE_ADDR' => '172.16.1.2'
        expect(last_response.header['X-RateLimit-Remaining']).to eq(58)
      end

      it 'does not include X-RateLimit-Limit, X-RateLimit-Remaining and X-RateLimit-Reset if the block return nil' do
        get '/'
        expect(last_response.header).not_to include('X-RateLimit-Limit')
        expect(last_response.header).not_to include('X-RateLimit-Remaining')
        expect(last_response.header).not_to include('X-RateLimit-Reset')
      end
    end

    describe 'without an additional block' do
      it 'identifies users by their address IP' do
        2.times { get '/', {}, 'REMOTE_ADDR' => '172.16.1.1' }
        expect(last_response.header['X-RateLimit-Remaining']).to eq(58)

        5.times {get '/', {}, 'REMOTE_ADDR' => '172.16.1.2' }
        expect(last_response.header['X-RateLimit-Remaining']).to eq(55)
      end
    end
  end

  describe 'custom memory storage' do
    let(:external_memory) { ExternalMemory.new }
    let(:rate_limiter_options) { { limit: 30, memory: external_memory } }
    let(:rake_limiter_customization_block) { Proc.new { |env| Rack::Request.new(env).params['API_TOKEN'] } }

    it 'stores all data in the external memory' do
      current_time = Time.now
      Timecop.freeze(current_time)
      get '/', { 'API_TOKEN' => 'ighVrvNmkLvWmjlFUZHzYQ' }
      Timecop.return

      expect(external_memory.get('rate_limit')).to eq(30)
      expect(external_memory.get('users')['ighVrvNmkLvWmjlFUZHzYQ'][:remaining_requests]).to eq(29)
      expect(external_memory.get('users')['ighVrvNmkLvWmjlFUZHzYQ'][:reset_time]).to eq(time_after_an_hour(current_time).to_i)
      expect(external_memory.get('customization_block')).to eq(rake_limiter_customization_block)
    end
  end
end

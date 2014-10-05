require 'rack/test'
require 'rate_limiter'
require 'timecop'

RSpec.configure do |config|
  config.include Rack::Test::Methods
end

def time_after_an_hour(time)
  time + 60*60
end

class ExternalMemory
  def initialize
    @memory = Hash.new
  end

  def get(attribute)
    @memory[attribute.to_s]
  end

  def set(attribute, value)
    @memory[attribute.to_s] = value
  end
end

require 'rack/test'
require 'rate_limiter'
require 'timecop'

RSpec.configure do |config|
  config.include Rack::Test::Methods
end

def time_after_an_hour(time)
  time + 60 * 60
end

class ExternalMemory
  def initialize
    @memory = Hash.new
  end

  def get(attribute)
    data = @memory[attribute.to_s]
    data ? data.dup : nil
  end

  def set(attribute, value)
    @memory[attribute.to_s] = value
  end
end

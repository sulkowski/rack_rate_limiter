# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack/rate_limiter/version'

Gem::Specification.new do |spec|
  spec.name          = 'rack_rate_limiter'
  spec.version       = Rack::RateLimiter::VERSION
  spec.authors       = ['Paweł Sułkowski']
  spec.email         = 'sulkowski.pawel@gmail.com'
  spec.summary       = 'Rack middleware imitating GitHub’s API Rate limiting'
  spec.homepage      = 'https://github.com/sulkowski/rack_rate_limiter'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
end

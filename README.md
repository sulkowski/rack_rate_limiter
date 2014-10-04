Pilot Academy — Workshop #5
================

##Rack::RateLimiter
The Rate Limiter will be implemented as a Rack middleware similarly to GitHub’s API ( https://developer.github.com/v3/#rate-limiting ).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rack_rake_limiter', git: 'git://github.com/sulkowski/rack_rate_limiter.git'
```

In your application add:
```
require 'rack_rate_limiter'
```

## Contributing

1. Fork it ( https://github.com/sulkowski/rate_limiter/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

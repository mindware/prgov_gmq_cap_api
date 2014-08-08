# A sample Gemfile
source "https://rubygems.org"
gem 'tilt' # used by the public/index.erb
gem 'goliath', "~> 1.0.4" # our webserver
gem 'grape', "~> 0.8.0"   #  our API engine
gem 'grape-entity', "~> 0.4.3" # our api entity presentation layer
gem 'dotenv'  # to hide our environment variables
gem 'foreman' # for our procfile, to load all relevant processes.
gem 'erubis' # for auto escaping HTML - http://www.sinatrarb.com/faq.html#escape_html

# Redis-Rb Dependencies:
gem "redis", "~> 3.0.1" # starting with version 2.2.0, redis-rb is thread-safe by default.
gem "hiredis", "~> 0.4.5" # redis-rb synchrony driver requires hiredis. JRuby incompatible with hiredis.
gem "em-synchrony", "~> 1.0.3" # for redis-rb synchrony driver. Allows compatibility with EventMachine async I/O.

# State Machine support for Transactions
gem 'aasm', "~> 3.2.0"

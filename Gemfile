# A sample Gemfile
source "https://rubygems.org"

gem 'tilt'
gem 'goliath'
gem 'grape'
gem 'grape-entity'
gem 'dotenv'
gem 'foreman'
gem 'erubis' # for auto escaping HTML - http://www.sinatrarb.com/faq.html#escape_html

# Redis-Rb Dependencies:
gem "redis", "~> 3.0.1" # starting with version 2.2.0, redis-rb is thread-safe by default.
gem "hiredis", "~> 0.4.5" # redis-rb synchrony driver requires hiredis. JRuby incompatible with hiredis.
gem "em-synchrony" # for redis-rb synchrony driver. Allows compatibility with EventMachine async I/O.

# Object Relational Mapping
gem "moneta", "~> 0.7.20" 	# Unified interface for key/value stores. Allows for atomic actions. 
gem "toystore", "~> 0.13.2" 	# The ORM on top of moneta

# State Machine support for Transactions
gem 'aasm', "~> 3.2.0"

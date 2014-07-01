require 'bundler/setup'
Bundler.require	# Load our Gemfile

require 'em-synchrony/em-http'
require 'goliath/test_helper'
require 'yajl/json_gem'

Goliath.env = :test

RSpec.configure do |c|
  c.include Goliath::TestHelper, :example_group => {
    :file_path => /test\//
  }
end

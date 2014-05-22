# require "hiredis"
# require "em-synchrony"
# require"redis/connection/synchrony"
# require "redis"
#
# EM.synchrony do
# redis = Redis.new :driver => :synchrony
# puts "connected"
# redis.set("mykey", "hello world")
# end

require 'redis'
require 'redis/connection/synchrony'

redis = Redis.new
puts "connected"
redis.set("mykey", "hello world")

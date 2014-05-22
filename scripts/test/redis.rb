require 'redis'
require 'hiredis'
require 'em-synchrony'


EM.synchrony do
    redis = Redis.new :driver => :synchrony
    puts "connected"
    redis.set("mykey", "hello world")
    key = redis.get("mykey")
    puts key
end

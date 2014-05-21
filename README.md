Requirements:
* Install ruby > 2.0
* Install rubygems

To start the Server:
* bundle install
* foreman start


Use of the Redis Gems:
We use Redis-rb, whose synchrony driver adds support for em-synchrony. This makes redis-rb work with EventMachine's asynchronous I/O, while not changing the exposed API. The hiredis gem needs to be available as well, because the synchrony driver uses hiredis for parsing the Redis protocol.

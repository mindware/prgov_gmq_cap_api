#!/usr/bin/env ruby
require 'adapter/redis'
require 'toystore'

module PR
	class Store
		def self.db
			begin
				# not using the synchrony driver yet
				@db = Redis.new
			rescue Exception => e
				puts "caught. #{e.message}"
			end
		end
	end
end
module PR
		class Hello
			include Toy::Store
			# store :redis, PR::Store.db
			# adapter :redis, Redis.new
			#Adapter[:redis], PR::Store.db
			attribute :world, String
		end
end

PR::Hello.adapter :redis, Redis.new
hi = PR::Hello.create(:world => 'hello')
puts hi.world
hi.write('mundo', 'bueno')
hi.adapter.write('hello', 'world')
hi.read('mundo')
puts hi.adapter.read('hello')

# begin
# 	hi = PR::Hello.create(:world => "Hello world! Solar Freaking Roads!")
# 	# hi = Adapter[:redis].new(PR::Store.db)
# 	# PR::Hello.adapter :redis, PR::Store.db
# 	# hi = PR::Hello.create(:world => 'hello')
# rescue Exception => e
# 	puts "Error: #{e.message}\n#{e.backtrace.join("\n")}"
# 	exit
# end
# # puts hi.class.ancestors.to_s
# # puts hi.class.adapter.class.ancestors[2].new.methods.sort.to_s
# puts hi.id
# puts hi.write("hello", "world")
# puts hi.adapter.class.ancestors[2].methods

# puts hi.persisted?
# puts hi.world
# puts hi.id
# puts "Class: #{hi.class.to_s} has the following methods: #{hi.methods.join("\n")}"
# hi.write("hello", "world!")
# puts "Hello: #{hi.hello}"
# puts "Hello: #{hi.read("hello")}"
# puts "boom"
#puts "deleting.."
#puts hi.delete

#!/usr/bin/env ruby
require 'toystore'
require 'adapter'
require 'adapter/redis'
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
		#Adapter[:redis], PR::Store.db
		Adapter[:redis].new(Store.db)
		attribute :world, String
	end
end
begin
	# hi = PR::Hello.create(:world => "Hello world! Solar Freaking Roads!")
	hi = Adapter[:redis].new(PR::Store.db)
rescue Exception => e
	puts "Error: #{e.message}\n#{e.backtrace.join("\n")}"
	exit
end
puts hi.to_s
# puts hi.persisted?
# puts hi.world
# puts hi.id
# puts "Class: #{hi.class.to_s} has the following methods: #{hi.methods.join("\n")}"
hi.write("hello", "world!")
# puts "Hello: #{hi.hello}"
puts "Hello: #{hi.read("hello")}"
puts "boom"
#puts "deleting.."
#puts hi.delete

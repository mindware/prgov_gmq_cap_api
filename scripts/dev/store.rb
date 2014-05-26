require 'moneta'
require 'toystore'
require 'adapter/memory'
module PR
	class Store
		def self.db
			begin
				@db = Moneta.new(:Redis, threadsafe: true, :expires => false)
			rescue Exception => e
				puts "caught. #{e.message}"
			end
		end
	end
end
module PR
	class Hello
       		include Toy::Store
       		adapter :memory, PR::Store.db
	
       		attribute :world, String
	end
end

begin
	hi = PR::Hello.create(:world => "Hello world! Solar Freaking Roads!")
rescue Exception => e
	puts "#{e.message}"
	exit
end

puts hi.to_s
puts "Persisted: #{hi.persisted?}"
puts hi.world
puts hi.id
#puts "deleting.."
#puts hi.delete

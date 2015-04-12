require '../lib/rest'

user = ENV["API_USER"]
pass = ENV["API_PASSWORD"]
total = 0

# Iterate through Ids to delete. 
# usage: ruby delete.rb id1 id2 ... idn
ARGV.each do |id| 
	total += 1
	# credentials via basic auth
	url = "http://localhost:9000/v1/cap/transaction/#{id}"
	result = `curl -u #{user}:#{pass} -i -X DELETE http://localhost:9000/v1/cap/transaction/#{id}`
	puts result
end

puts "Done! (#{total} iterations)"

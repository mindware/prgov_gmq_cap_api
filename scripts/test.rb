%w{job tube mass_queue}.each do |x| require "../app/models/#{x}" end

puts MassQueue.setup
t = MassQueue.find "default"
puts t
puts "#{t.queues}"
j = MassQueue.add("{ 'job' : 'hi' }", "default") 
j = MassQueue.add("{ 'job' : 'howdy ho' }", "default") 
puts "Job: #{j} added"
puts "#{t.queues}"
j = MassQueue.reserve("default", 1)
show(j, t)
j = MassQueue.reserve("default") # also interepreted as reserve one
show(j, t)
j = MassQueue.reserve("test") # also interepreted as reserve one
show(j, t)

def show(j, t)
	puts "Reserve: id is #{j.class}" 
	if !j.nil?
		if j.class == Array
			j.each do |x| 
				puts "#{x} is a job with id #{x.id} and body #{x.data}"
			end
		else
			puts "Task to do is #{j.body}"
			puts "#{t.queues}"	
			puts "This is the last reserved id: #{t.peek("reserved").id}"
		end
	end
end

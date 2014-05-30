# this was just an exercise to see if we could use
# zlib to compress certificates, and then send over
# the line using base64. Turns out, that's not a great
# idea. With the jpg sample, the compression was minimal
# while the base64 actually made the whole thing a lot
# bigger. Ie: compressed: about 20 chars less
# on a 120k chars file. After base64, it blew up 
# by the thousands. I'll try this again with the 
# original cert. Maybe it has low entropy.  
require 'zlib'
require 'base64'

def compress(data) 
	compressed = Zlib::Deflate.deflate(data) 
	base64     =  Base64.strict_encode64(compressed)
	puts "Compressing from length of: #{data.length}" 
	puts "Compressed to length of: #{compressed.length}" 
	puts "Base64 compressed length: #{base64.length}" 
end

file = File.open("../test/sijc/sample/sagan.jpg", "rb")
contents = file.read
compress(contents)

data = "some repeating string is great for compression, images not so much" * 100
compress(data)

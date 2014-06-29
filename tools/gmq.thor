# Command line tool for generate users for
# the PR.Gov GMQ API system.
# Developed by: Andrés Colón
# Date: 2014-05-20 4:55AM
require 'json'
require 'digest/md5'
require 'securerandom'
require 'thor'

class Gmq < Thor

	class Generate < Thor
		desc "user <name> <group1>, <group2>...",
		     "Generate a user info to paste to the config file."
		def user(name, *groups)
			puts "Your #{name} would belong to #{groups}"
			key = password()
			result = { name => { "passkey" => "#{key}",
			                     "groups" => groups}}.to_json.to_s
			puts "\nAppend this to the '../config/users.json', taking care to add "+
			     "the proper commas in the file:"
			puts "\t#{result[1..-2]}"
		end

		desc "password", "generates a proper CAP API password for the user and "+
		                 "hashed and salted pass-key for the API configuration"
		def password

			# The API system will expect a hex string, with a lenght of 24.
			# Here we specify n as 12 in order to guarantee a length of 24,
			# since the length is always twice of n with SecureRandom.hex.
			# The salt will be appended to the hash to create the passkey.

			# The passkey will be used, the salt extracted and ran against
			# the system. This is just to make rainbow tables impractical
			# Each user password is auto-generated salted and jumbled up.
			# So long as the users keep their passwords safe, someone
			# could steal a copy of the config file and still be unable to
			# authenticate. Users must safeguard their passwords once generated
			# and the passwords must travel through a tunnel on insecure lines.
			random_salt = SecureRandom.hex(12)
			random_password = SecureRandom.hex(12)
			hash = Digest::MD5.hexdigest(random_password + random_salt)
			puts "Hand this password (securely) to the user: #{random_password}"
			#puts "The salt for the system: #{random_salt}"
			# puts "The pass-key for the system: #{hash}"
			puts "This is the pass-key for the system: #{random_salt + hash}"
			return "#{random_salt + hash}"
		end
	end
end

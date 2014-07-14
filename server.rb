#!/usr/bin/env ruby

# First, fix the paths so that everything under this directory
# is in the ruby path. This way we don't have to include relative filepaths
$: << File.expand_path(File.dirname(__FILE__))

# We're using bundler to include our gems
require 'bundler/setup'
# Load our Gemfile
Bundler.require
# Load environment variables
Dotenv.load
# Load the GMQ API
require 'app/api'
# Spice up the String class with color capabilities.
require 'app/helpers/colorize'

# Here we start defining the Web Server that will handle http requests properly:
class Server < Goliath::API

	# we include rack templates so we can use erb
	include Goliath::Rack::Templates
	# respond to http requests

	def initialize()
		begin
			ascii = File.open("docs/GMQ_ASCII", 'r') { |f| f.read }
			puts ascii.gsub("█", "█".bold.green).gsub("-", "-".red).
			     gsub("=", "=".red).gsub("╗", "╗".black).gsub("╔", "╔".black).
			     gsub("═","═".black).gsub("╝","╝".black).gsub("║", "║".black).
			     gsub("▀▀","▀▀".bold.green).gsub("╚","╚".black).gsub("▄","▄".black)
			ascii = ''
		rescue Exception => e
		ensure
			puts "GMQ CAP API Server is starting "+
			     "up in #{((Goliath.env.to_s.capitalize) + (" Mode")).bold.brown}."
		end
		# Check the configuration files are there.
		# If any corrupt configurations an error will be thrown
		begin
			if(PRGMQ::CAP::Config.check)
				  puts "Configuration loaded correctly."
			end
		rescue Exception => e
					puts "WARNING: #{e.message}"
					exit
		end

		# # Establishes and check db connection
		# if (PRGMQ::CAP::Store.connected?)
		# 		puts "established connection!"
		# else
		# 		puts "WARNING: Connection to Storage Failed! We will try reconnecting "+
		# 		"until it comes back online."
		# end
		# puts "Lets wait this out..."
		# while !PRGMQ::CAP::Store.connected?
		# 	sleep 1
		# 	puts PRGMQ::CAP::Store.connected?
		# end
		# This takes a while to connect and it does so asynchronously,
		# so no way to know if its already connected until a request is done.
		# PRGMQ::CAP::Store.connected?
	end

	def response(env)
		# any specific html document request that meets a criteria, we handle
		# through the public directory:
		if env['REQUEST_PATH'] == '/admin' or env['REQUEST_PATH'] == '/panel/'
			[200, {}, erb(:index, :views => Goliath::Application.root_path('public'))]
		else
			# everything else, we route through the Grape RESTful API
			PRGMQ::CAP::API.call(env)
		end
	end
end # end of class

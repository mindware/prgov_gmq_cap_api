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

  ########################################################
	#   						Webserver HTTP Responses							 #
	########################################################

	# Respond to HTTP Requests properly.
	def response(env)
		# any specific html document request that meets a criteria, we handle
		# through the public directory, by servering the proper html files:

		# Print out a message indicating IP and path being requested.
		debug "#{env['REMOTE_ADDR'].cyan} requests '#{env["REQUEST_PATH"].bold.cyan}'"
		if env['REQUEST_PATH'] == '/panel/'
			[200, {}, erb(:index, :views => Goliath::Application.root_path('public'))]
		else
			# Everything else is processed by our GMQ CAP API Middlware:
			# Here we route through the Grape RESTful API:
			PRGMQ::CAP::API.call(env)
		end
	end


	########################################################
	#   						Webserver Startup	Method							 #
	########################################################

	def initialize
		begin
			# Load the startup ASCII and spice it up:
			ascii = File.open("docs/GMQ_ASCII", 'r') { |f| f.read }
			puts ascii.gsub("█", "█".bold.green).gsub("-", "-".red).
			     gsub("=", "=".red).gsub("╗", "╗".black).gsub("╔", "╔".black).
			     gsub("═","═".black).gsub("╝","╝".black).gsub("║", "║".black).
			     gsub("▀▀","▀▀".bold.green).gsub("╚","╚".black).gsub("▄","▄".black)
			# once we're done with the startup screen, clear the buffer.
			ascii = ''
		rescue Exception => e
		ensure
			# Check the configuration files are there.
			# If any corrupt configurations an error will be thrown
			begin
				if(PRGMQ::CAP::Config.check)
						puts "Configuration loaded correctly."
				end
			rescue Exception => e
						warning "WARNING: #{e.message}"
						exit
			end
			puts "GMQ Webserver is starting "+
			     "up in #{((Goliath.env.to_s.capitalize) + (" Mode")).bold.brown}"+
					 "...waiting for requests."
		end

		# Establishes and check db connection
		# Unfortunately, this won't work, since EventMachine is not yet up,
		# so the EM::Synchrony connection pool will not be ready yet. Redis-Rb
		# lazily connects, so only when the first connection happens will we be
		# knowing if the Store connected or not. We might improve this later.
		# Ideally, we'd know if the Store is having problems at load time.
		#
		# if (PRGMQ::CAP::Store.connected?)
		# 		puts "Established connection to the Transaction STore!"
		# else
		# 		puts "WARNING: Connection to Storage Failed! We will try reconnecting "+
		# 		"until it comes back online."
		# end
	end

	########################################################
	# 						Webserver Helper Methods								 #
	########################################################

	# An alias to our logger. We're use this in the debugger.
	def logger
		PRGMQ::CAP::Config.logger
	end

	# Prints details if we're in debug mode and logs them properly
	def debug(str, use_title=false)
			# title = "DEBUG: " if use_title
			title = "Webserver: ".bold.green
			str = str.to_s
			# print to screen
			puts "#{title}#{str}" if PRGMQ::CAP::Config.debug
			# strip of colors and log each line
			str.split("\n").each do |line|
				logger.info line.no_colors
			end
	end

  # Logs and outputs warnings
	def warning(str)
		  puts str if PRGMQ::CAP::Config.debug
		  logger.warn str.no_colors
	end
end # end of class

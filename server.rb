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

# Here we start defining the Web Server that will handle http requests properly:
class Server < Goliath::API

	# we include rack templates so we can use erb
	include Goliath::Rack::Templates
	# respond to http requests

	def initialize()
		puts "PR.Gov's GMQ API Server is starting up in #{Goliath.env.to_s.capitalize}"
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

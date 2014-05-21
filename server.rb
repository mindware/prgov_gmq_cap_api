#!/usr/bin/env ruby
require 'bundler/setup'
Bundler.require	# Load our Gemfile
Dotenv.load     # Load environment variables
require './app/api'

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
		if env['REQUEST_PATH'] == '/admin' or env['REQUEST_PATH'] == '/admin/'
			[200, {}, erb(:index, :views => Goliath::Application.root_path('public'))]
		else
			# everything else, we route through the Grape RESTful API
			PRGMQ::CAP::API.call(env)
		end
	end
end # end of class

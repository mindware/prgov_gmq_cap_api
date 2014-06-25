module PRGMQ
	module CAP
		module LibraryHelper

			# When this is called, the user has *already* been authenticated.
			# He had proper credentials to get into the API. Here we retrieve his
			# groups to check if he is able to access a resource only available to
			# allowed_groups.
			def allowed?(allowed_groups)
				# we grab the current user from the environment. This is after
				# said user has passed the scrutiny of a basic authentication.
				user = Authentication.find_user(env["REMOTE_USER"])
				# User should exist because we passed basic_auth to get here,
				# but just in case it got deleted after we got acess, throw an error:
				raise InvalidCredentials if (!user)
				# Check if the user is allowed into the specified groups
				# we do this by checking the intersection of both arrays
				if(!(user.groups & allowed_groups).empty?)
						return user
				else
						raise InvalidAccess
				end
			end

			def logger
				# This will return an instance of the Logger class from Ruby's
				# standard library. The standard logger class is Thread-safe, btw.
				Config.logger
				# API.logger.new('foo.log', 10, 1024000)
				# Grape::API.logger = Logger.new(File.expand_path("../logs/#{ENV['RACK_ENV']}.log", __FILE__))
			end

			def user_list
					Config.users.keys
			end

			def security_group_list
					Config.groups
			end


			def total_visits
					visits = Stats.visits
					visits.nil? ? 0 : visits
			end

			# Prints details if we're in debug mode
			def debug(str, use_title=false)
				  title = "DEBUG: " if use_title
				  puts "#{title}#{str}" if Config.debug
					logger.info str
			end
			#
			# def log(str)
			# 		puts "#{str}" if Config.logging
			# end

			def last_10_transactions
					Store.db.lrange(Transaction.db_list, 0, -1)
			end

			def request_info
				"Incoming Request Data:\n"+
				"User: #{env["REMOTE_USER"]} (#{env["REMOTE_ADDR"]})\n"+
				"URI: #{env["REQUEST_URI"]}\n"+
				"Time: #{Time.now.strftime("%m/%d/%Y - %r")}\n"+
				"JSON Payload:\n#{env["api.request.input"]}\n"+
				"Description:\n#{route.route_description}\n"
			end

		end
	end
end

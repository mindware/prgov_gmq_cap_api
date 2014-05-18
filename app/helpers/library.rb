module PRGMQ
	module CAP
		module Library

			def error(e)
				puts "::Error:: PRGMQ CAP API Server encountered an error: "+
						 "\n#{e.inspect}\n#{e.backtrace.join("\n")}"
			end

			# Determines if this user is allowed by belonging to an authorized group.
			def allowed?(username, allowed_groups)
				user = Authentication.find_user(username)
				# User should exist because we passed basic_auth to get here,
				# but just in case it got deleted after we got acess, throw an error:
				error!(InvalidCredentials.data,  InvalidCredentials.http_code) if(!user)
				# Check if the user is allowed into the specified groups
				# we do this by checking the intersection of both arrays
				if(!(user.groups & allowed_groups).empty?)
						return user
				else
						error!(InvalidAccess.data,  InvalidAccess.http_code)
				end
			end

			def logger
				# This will return an instance of the Logger class from Ruby's
				# standard library.
				API.logger
			end
			
		end
	end
end

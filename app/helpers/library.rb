module PRGov
	module Cap
		module Library
			def self.error(e)
				puts "::Error:: PRGov CAP API Server encountered an error: \n#{e.inspect}\n#{e.backtrace.join("\n")}"
			end

			def current_user
			end

			def authenticate!
       	error!('401 Unauthorized', 401) unless current_user
			end

		end
	end
end

require 'json'

module PRGMQ
  module CAP
      class Config

          class << self
              attr_reader :all, :backtrace_errors, :debug, :users, :downtime,
                          :logging, :logger, :system
              attr_writer :downtime
          end


          # General Class Defaults:
          @all = nil
          # if Goliath is defined
          if(Object.const_defined?('Goliath'))
            # Set debug to true if we're in development mode.
            @debug = (Goliath.env.to_s == "development")
          else
            puts "WARNING: Config could not determine current environment "+
                 "from Webserver. Are we not using Goliath? This will affect "+
                 "API's Config.environment method for checking environment and "+
                 "displaying debugging information. For now, we'll default "+
                 "into 'production' for safety, but this needs "+
                 "fixing if you ever want to see debugging information! "+
                 "Please look into it."
            @debug = false
          end

          @logging = true
          # Sets backtrace for unexpected exceptions/works only if debug is true
          @backtrace_errors = false
          # variable that determines if we're down for maintenance.
          @downtime = false


          # Gets the current environment (production, development, testing)
          # from the Webserver. At this time, we use Goliath for its awesome
          # asynchronous EM capabilities.
          def self.environment
            if(Object.const_defined?('Goliath'))
               Goliath.env.to_s
            else
              # By default if we can't determine our environment,
              # we'll go into production mode. This could happen if someone
              # changed our webserver from Goliath to some other wordly
              # webserver. We'll need a way to get the current environment
              # from that webserver.
               "production"
            end
          end

          # This determines the log file
          # For alternative configuration see:
          # http://www.ruby-doc.org/stdlib-2.1.2/libdoc/logger/rdoc/Logger.html
          def self.logger
            # @logger ||= Logger.new('logs/foo.log', 'daily')
            # Taking into considerations daily backups at unknown hours, we
            # could use the weekly option for now and reduce it only if it
            # turns out log files in a week become too huge, with the following:
            # @logger ||= Logger.new('logs/foo.log', 'weekly')

            # Alternatively, to make sure we don't store more than a
            if @logging
              #  @logger ||= Logger.new("logs/#{self.environment}.log", 10, 10024000)
              @logger ||= Logger.new("logs/#{self.environment}.log",
                                     @all["system"]["logs_max_retention"],
                                     @all["system"]["logs_max_bytes"])
            else
              # If we're not logging, we default to STDOUT
              API.logger
            end
          end

          # Returns the entire config for users. Used for authentication
          # so this hash will contain passkeys. Tread lightly.
          def self.users
            # Make sure the server's config is loaded. Loads it if it isn't.
            self.check
            # @all["users"] = nil
            return @all["users"] if @all.has_key? "users"
            # if for some reason it doesn't exist, and no users exist,
            # so lets create the empty list in memory.
            @all["users"] = {}
            return @all["users"]
          end

          def self.groups
            # Make sure the server's config is loaded. Loads it if it isn't.
            self.check
            if @all.has_key? "users"
               # we'll temporary save all the groups found in the config here
               groups = []
               # if the config has a users hash
               if (@all["users"].length > 0)
                   # iterate through the users hash
                   @all["users"].each do |name, key|
                       # if the user has groups key
                       if(key.has_key? "groups")
                         if(key["groups"].is_a? Array)
                           # grab the groups array from the hash
                           groups << key["groups"]
                         else
                           # user doesn't have a security group as an array
                           # ['sijc', 'webapp'] etc, but something else.
                           raise InvalidConfigFile
                         end # end of check if groups is an Array
                       else
                         # user doesn't have a security group
                         raise InvalidConfigFile
                       end # end of check if user has security group
                   end # end of iteration through users

                   # create a unique list of security groups and sort them
                   groups = groups.flatten.uniq.sort
               end
               # don't go past this point, since we had something in the config
               return groups
            end
            # if for some reason it doesn't exist, and no users exist,
            # so lets create the empty list in memory.
            @all["users"] = {}
            # Now return an empty list of security groups
            return []
          end

          def self.check
              # here we check if the config is already loaded in memory
              if @all.nil?
                @all       = self.load_config
                @debug     = @all["system"]["debug"]  unless @all["system"]["debug"].nil?
                @backtrace = @all["system"]["backtrace_errors"] unless @all["system"]["backtrace_errors"].nil? and @debug
                @logging   = @all["system"]["logging"] unless @all["system"]["logging"].nil?
                puts "Loading configuration." if @debug
                puts "logging: #{@logging} - debug: #{@debug} - backtrace: #{@backtrace}"
              #else
                #  puts "Reading configuration from memory." if @debug
              end
              return true
          end

          def self.load_config
             # This is a system for systems. Since it's not designed to have
             # a dynamic amount of users registering, mainly applications
             # we won't be doing round trips to check for users in a db,
             # as that will introduce latency into the system. Instead
             # we'll have a file in trusted directory, with salted/hashed
             # password and a tool to generate passwords for these users.
             user_config = get_json_from_file("config/users.json")
             db_config   = get_json_from_file("config/db.json")
             system_config = get_json_from_file("config/system.json")
             @all = {
                         "users"   => user_config,
                         "db"      => db_config,
                         "system"  => system_config
             }
             # clean up memory
             user_config, db_config, system_config = nil,nil, nil
             return @all
          end

        	# Returns the JSON contents of the file.
        	def self.get_json_from_file(file)
            begin
          		# where we'll store our data
          		data = ""
          		# open the file to get the contents
              # if it doesn't exist, it'll error out and we'll catch it.
          		file = File.new(file, "r")
          		# read the file and load up the data within it to memory
          		file.each do |line|
          			# read each line
          			data << line
          		end
          		# close the file, since we're done for now
          		file.close()
              rescue Exception => e
                # When in doubt, print errors.
                raise MissingConfigFile
              end
              begin
          		# convert the data to JSON:
        			data = JSON.parse(data)

              rescue Exception => e
                # When in doubt, print errors.
                raise InvalidConfigFile
              end
        		return data
        	end
      end
  end
end

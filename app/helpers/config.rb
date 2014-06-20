require 'json'

module PRGMQ
  module CAP
      class Config

          class << self
              attr_reader :all, :backtrace_errors, :debug, :users, :downtime,
                          :logging
              attr_writer :downtime
          end

          # def error(str)
          #   logger.warning str
          # end

          @all = nil
          # if Goliath is defined
          if(Object.const_defined?('Goliath'))
            # Set debug to true if we're in development mode.
            @debug = (Goliath.env.to_s == "development")
          else
            @debug = false
          end

          @logging = false

          # Sets backtrace for unexpected exceptions
          @backtrace_errors = false
          # variable that determines if we're down for maintenance.
          @downtime = false

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
              if @all.nil?
                @all = self.load_config
                 puts "Loading configuration." if @debug
              # else
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
             @all = {
                         "users" => user_config,
                         "db"    => db_config,
             }
             user_config, db_config = nil,nil
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

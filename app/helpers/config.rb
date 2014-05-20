require 'json'

module PRGMQ
  module CAP
      class Config

          class << self
              attr_reader :data, :backtrace_errors
          end

          # def error(str)
          #   logger.warning str
          # end

          @data = nil
          @backtrace_errors = false


          def self.check
              if @data.nil?
                 puts "Loading configuration."
                 @data = self.load_config
              else
                 puts "Configuration already loaded. #{@data}"
              end
              true
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
             @data = {
                         "users" => user_config,
                         "db"    => db_config,
             }
             user_config, db_config = nil,nil
             return @data
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
                raise InvalidConfigFile
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

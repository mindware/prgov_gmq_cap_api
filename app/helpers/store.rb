# Load our external storage libraries
require 'app/helpers/library'
require 'em-synchrony'                       # Fiber aware connection pools
require 'redis'				  										 # use redis
require 'redis/connection/synchrony'         # use the asynchronous driver


module PRGMQ
  module CAP
    # The Store class is not meant to be an instance. We use this
    # class and its methods to pool connections to specific Store,
    # thus making more efficient use of said connections.
    # All Store selections have taken thread-safety into account.
    # Do not add a Store sub-system that isn't thread safe to use.
    class Store

      class << self
          include LibraryHelper
      end


      # We're using Redis: rather than thinking about redis as
      # a database with some kind of non-existent relationship to SQL,
      # try to think of it as a data structure server with a rich set of
      # commands for querying and manipulating those data structures
      # over a network connection.

      def self.system_prefix
        "gmq"
      end

      # When storing data, we'll want a specific structure in Redis
      # so our keys will be easier to organize and retrieve.
      # The following method defines the structure for all keys to be
      # stored in the db. They will all begin with the prefix
      # defined below. They will be used in the following way
      # prefix:object:id, such that 'transactions' in an
      # API called 'cap' will be stored in the following way:
      # 'cap:tx:id'
      def self.db_prefix
        "#{system_prefix}:cap"
      end

      # Let's also make this a class method, so we can
      # pool this connection across the entire API.
      # Our backend is Redis, and Redis is single-threaded so
      # pooling actually makes using this more efficient.
      def self.db
        # do checks to see if connection failed, grab those.
        begin
          # If you change the storage backend, please update the
          # errors.rb system to reflect the change, by
          # adding a check for the Exceptions of the driver
          # of the new backend you install. At this time, it catches
          # Redis Errors.

          # I've tested this by killing the storage server and
          # later reconnecting. The system automatically reconnects after
          # failure.

          # Todo:
          # We later could add selection of the host based on failure. We
          # could alternate between known hosts (keys) based on the availability
          # Todo cancelled:
          # However: by using twemproxy we've eliminated the need to do the
          # manual hopping among hosts. And we'll alternate between twemproxies
          # using VRRP.
          if(@db.nil?)
              # First we choose the driver. By default we use the synchrony one.
              # If we weren't running on Eventmachine, we'd use a different one
              # such as hiredis
              debug "connecting to #{Config.db_name} at #{Config.db_host}:#{Config.db_port} "+
                    "(using #{Config.db_driver} driver with a pool_size of #{Config.db_pool_size})..."
              @db = EventMachine::Synchrony::ConnectionPool.new(size: Config.db_pool_size) do
                    Redis.new(:host =>   Config.db_host,
                              :port =>   Config.db_port,
                              :driver => Config.db_driver,
                              :db     => Config.db_id)
              end
          else
              @db
          end
        rescue Exception => e
           raise e
          # raise StoreUnavailable
        end
      end

      # A quick check on the db. If we're disconnected, we connect.
      # This is used when the server is loading up to force a simple
      # connection, without needing to query for anything specific.
      # Redis-rb lazily connects (ie, only when an action is performed)
      # does it establish the connection. So if this is the first time
      # we need to ping it to check if the server is really available
      # or not.
      def self.connected?
          # If db is ever nil, we return false
          return false if self.db.nil?
          # if we know we're connected,
          return true  if self.db.connected?
          # If we don't know if we're connected,
          # lets connect and PING the server. If we get an exception
          # the server is unavailable, otherwise its up.
          # Note:
          # This will work on API startup, but not on WebServer initial startup.
          # Unfortunately, this doesn't work on webserver startup, because
          # eventmachine hasn't started at that point yet. So it's not possible
          # to tell the WebServer at load time that the Storage is down.
          # It requires EM to be up first. We'll use this when the API starts
          # which will happen upon the first request.
          begin
            self.db.ping
            return true
          rescue Exception => e
            return false
          end
      end

    end
  end
end

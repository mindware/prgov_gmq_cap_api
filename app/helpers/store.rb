module PRGMQ
  module CAP
    # The Store class is not meant to be an instance. We use this
    # class and its methods to pool connections to specific Store,
    # thus making more efficient use of said connections.
    # All Store selections have taken thread-safety into account.
    # Do not add a Store sub-system that isn't thread safe to use.
    class Store

      # We're using Redis: rather than thinking about redis as
      # a database with some kind of non-existent relationship to SQL,
      # try to think of it as a data structure server with a rich set of
      # commands for querying and manipulating those data structures
      # over a network connection.

      # When storing data, we'll want a specific structure in Redis
      # so our keys will be easier to organize and retrieve.
      # The following method defines the structure for all keys to be
      # stored in the db. They will all begin with the prefix
      # defined below. They will be used in the following way
      # prefix:object:id, such that 'transactions' in an
      # API called 'cap' will be stored in the following way:
      # 'cap:tx:id'
      def self.db_prefix
        "gmq:cap"
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
          if(@db.nil?)
            @db = Redis.new(:driver => :synchrony)
          else
             @db
          end
        rescue Exception => e
           raise e
          # raise StoreUnavailable
        end
      end

    end
  end
end

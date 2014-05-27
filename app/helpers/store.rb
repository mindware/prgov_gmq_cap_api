module PRGMQ
  module CAP
    # The Store class is not meant to be an instance. We use this
    # class and its methods to pool connections to specific Store,
    # thus making more efficient use of said connections.
    # All Store selections have taken thread-safety into account.
    # Do not add a Store sub-system that isn't thread safe to use.
    # At this time our system is able to reliably use many different
    # database backends, as it is agnostic to them via the use of
    # moneta. So we could be running on Redis, Memcache, SqlLite,
    # pure memory, even file disk and it would be transparent to
    # us, via our Toy::Store models and Moneta Store implementations.
    class Store

      # Let's make us independent of Store backend by using
      # Moneta. Let's also make this a class method, so we can
      # pool this connection across the entire API.
      # Our backend is Redis, and Redis is single-threaded so
      # pooling actually makes using this more efficient.
      def self.db
        # do checks to see if connection failed, grab those.
        begin
          # We're pretty much Store agnostic thanks to the next
          # line, however, this begin/rescue doesn't catch
          # errors like Redis::CannotConnectError at this time.
          # So, if you update the backend, please update the
          # errors.rb system to reflect the change, by
          # adding a check for the Exceptions of the driver
          # of the new backend you install.
          if(@db.nil?)
            #  @db = Moneta.new(:Redis, threadsafe: true, expires: false)
            @db = Redis.new(:driver => :synchrony)
          else
             @db
          end
        rescue Exception => e
           # nothing really gets caught here, this
           # rescue never really catches the errors from the
           # inability to connect by moneta to redis. The redis
           # client throws the error, and it is only caught
           # by our ApiErrorHandler Middleware defined in errors.rb
           raise e
          # raise StoreUnavailable
        end
      end

    end
  end
end

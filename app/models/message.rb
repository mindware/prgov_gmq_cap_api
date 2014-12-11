module PRGMQ
  module CAP
    class Message < PRGMQ::CAP::Base

      # Method to send emails.
      # If an existing db_connection is being used, it can be
      # specified as a parameter (only used on pipelined
      # requests to Redis).
      def self.email(params, db_connection=nil)
        whitelist = ["from", "to", "attachment",
                     "subject", "text", "html"]
        params = validate_email_parameters(params, whitelist)

        # Create the Json version of the Job for Resque.
        job = {
                "class" => "GMQ::Workers::EmailWorker",
                "args" => [{
                              "from" => params["from"],
                              "to"   => params["to"],
                              "subject" => params["subject"],
                              "text" => params["text"],
                              "html" => params["html"],
                              "queued_at" => "#{Time.now}"
                }]
        }
        enqueue(job.to_json, db_connection)
      end

      # Enqueues a job using a database connection.
      # If no database connection is specified, we grab
      # a new one from the Store.db. Reusing a db_connection
      # is allowed for those cases where this class is used
      # in a pipelined request to Redis, where a new
      # db_connection cannot be requested and the existing
      # one must be used.
      # When used outside a pipeline request, one can safely
      # leave db_connection nil.
      def self.enqueue(job, db_connection=nil)
        db_connection = Store.db if db_connection.nil?
        db_connection.rpush(queue_pending, job)
      end
    end
  end
end

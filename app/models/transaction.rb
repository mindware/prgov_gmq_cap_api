# The transaction class is the Object that represents a transaction as it is
# stored in the database. It uses the Base class, which holds the basic
# methods for representing the way keys are stored in the data Store (db).
#
# It allows for finding and creating transactions. It uses helper methods
# from the Validations module for both instance and class methods, to validate
# user input. It has whitelists, per API action, that determine which user
# parameters are taken into consdieration, while the rest are ignored. As such
# parameters that are sneaked into an action, where they are not expected, are
# immediately dropped (such as creating a new transaction and appending the
# certificate, or modifying the state).
#
# The transactoin uses Act As State Machine to create a set of states
# to track where a transaction is and where it is going next based on a
# predetermined workflow.
#
# Version v1:
# Andrés Colón Pérez
# Chief Technology Officer, Chief Security Officer
# Office of the CIO (Giancarlo Gonzalez)
# Government of Puerto Rico
# May - 2014
#
module PRGMQ
  module CAP
    class Transaction < PRGMQ::CAP::Base
      # We use both class and instance methods
      extend Validations
      include Validations
      include TransactionIdFactory
      extend TransactionIdFactory
      include LibraryHelper

      # Expiration: Transaction expiration means expiration from the DB
      # as in, disappearing from the system entirely.
      #
      # This shouldn't be confused with the expiration of a certificate.
      # A certificate could be invalidated by the PR.Gov validation system
      # even if its transaction still hasn't expired. For example, say it has
      # been determined that a certificate shouldn't be valid after 1 month,
      # in such a case PR.Gov validation mechanism could check the transaction
      # approval date and see if it has already reached its certificate
      # expiration limit. However, the Transaction expiration might still not
      # have come into effect, and thus, we could have the ability to peer into
      # the transaction for administrative and audit purposes long after the
      # certificate has already expired.
      #
      # Important Hint for Backup Restoration and Transaction Expiration:
      #
      # Administrators, "Hear ye, hear ye!". This is important.
      # Transaction expiration is going to be performed at the Storage level.
      # This means if you ever manually restore a backup, in order to peer at
      # old transactions, such as for an audit, it is important that the time
      # of the server is modified to the past in question, otherwise, the
      # storage system will see the time difference (Redis) and determine that
      # the transactions expiration time has come up, and immediately expire
      # data. This is because the storage mechanism that performs expiration of
      # keys does it using the current time. If you restore data from the past
      # into a server whose datetime is configured to the present or future,
      # expiration will come into effect for anythign that should be expired.
      #
      # If you set MONTHS_TO_EXPIRATION_OF_TRANSACTION to 0, transactions
      # will never expire. (Hint: that could fill up the database store, be
      # careful). Only do it if you know what you're doing or would like to get
      # fired. Seriously, don't do it.
      # By default, we use 1 or three months to keep the transaction in the
      # system for inspection. Once expired, it's really gone!
      # Max is 25 years (25 * 12). Don't try it.
      MONTHS_TO_EXPIRATION_OF_TRANSACTION = 3
      # The expiration is going to be Z months, in seconds.
      # Time To Live - Math:
      # 604800 seconds in a week X 4 weeks = 1 month in seconds
      # We multiply this amount for the Z amount of months that a transaction
      # can last before expiring.
      EXPIRATION = (604800 * 4) * MONTHS_TO_EXPIRATION_OF_TRANSACTION


      LAST_TRANSACTIONS_TO_KEEP_IN_CACHE = 50


      ######################################################
      # A transaction generally consists of the following: #
      ######################################################

      # If you add an attribute, update the initialize method and to_hash method
      attr_accessor :id,     # our transaction id
                    :email,                # user email
                    :ssn,                  # social security number
                    :license_number,       # valid dtop identification
                    :first_name,           # user's first name
                    :middle_name,          # user's middle name
                    :last_name,            # user's last name
                    :mother_last_name,     # user's maternal last name
                    :residency,            # place of residency
                    :birth_date,           # the date of birth
                    :reason,               # the user's reason for the request
                    :IP,                   # originating IP of the requester as
                                           # claimed/forwarded by client system
                    :system_address,       # the IP of the client system that
                                           # talks to the API
                    :language,             # User specified language
                    :status,               # the status pending proceessing etc
                    :state,                # the state of the State Machine
                    :history,              # A history of all actions performed
                    :location,             # the system that was last assigned
                                           # the Tx to
                    :created_at,           # creation date
                    :updated_at,           # last update
                    :created_by,           # the user that created this
                    :certificate_base64,   # The base64 certificate -
                                           # currently just a flag that lets us
                                           # know it was already generated so
                                           # we can pick it up in SIJC.
                                           # PR.Gov is no longer storing
                                           # certificates, when SIJC calls back
                                           # after generation. Due to a storage
                                           # issue related to RAM and Redis.
                                           # Instead, workers pick up the
                                           # certificate as they're ready to
                                           # email a certificate.
                    :analyst_fullname,     # The fullname of the analyst at
                                           # PRPD that authorized this request.
                    :analyst_id,           # The user id of the analyst at PRPD
                                           # that authorized this request
                                           # through their System.
                    :analyst_approval_datetime, # The exact date and time in
                                                # which the user approved this
                                                # action. This must correspond
                                                # with the tiemstamps in the
                                                # PRPD’s analyst system, such
                                                # RCI, so that in the event of
                                                # an audit correlation is
                                                # possible.
                    :analyst_transaction_id,    # The internal id of the
                                                # matching request in the
                                                # Analyst System. This id
                                                # can be used
                                                # in case of an audit.
                    :analyst_internal_status_id,# The matching internal
                                                # decision code id of the
                                                # system used by the analysts.
                    :decision_code,             # The decision of the analyst at
                                                # PRPD of what must be done with
                                                # transaction after their
                                                # exhaustive manual review
                                                # process. The following
                                                # decisions are supplied by the
                                                # PRPD system login only:
                                                # 100 - Issue Negative Cert
                                                # 200 - Positive Certificate
                    :identity_validated,        # This tells us if the citizen
                                                # was identified in a Gov db
                                                # nil: if nothing done yet
                                                # true: validated
                                                # false: failed validation
                    :emit_certificate_type,     # The type of certificate we
                                                # have been told we are to
                                                # receive and send:
                                                # "positive" - a positive cert
                                                # "negative" - a negative cert
                                                # This is set not only by the
                                                # decision_code when a fuzzy
                                                # result requires an PRPD
                                                # analyst, but also by
                                                # RCI when it determines
                                                # it has enough data to make a
                                                # decision.
                    :certificate_path           # The temporary file path to the
                                                # certificate in disk.
      # Newly created Transactions
      def self.create(params)

          # The following parameters are allowed to be retrieved
          # everything else will be discarded from the user params
          # by the validate_transaction_creation_parameters() method
          whitelist = ["email", "ssn", "license_number",
          "first_name", "middle_name", "last_name", "mother_last_name",
          "residency", "birth_date", "IP", "reason", "system_address",
          "created_by", "language" ]


          # Instead of trusting user input, let's extract *exactly* the
          # values from the params hash. This way, additional values
          # that may have been sneaked inside the params hash are ignored
          # safely and never reach the Store. This is done by the validate
          # method:
          # validate all the parameters in the incoming payload
          # throws valid errors if any are detected
          # it will remove non-whitelisted params from the parameters.
          params = validate_transaction_creation_parameters(params, whitelist)

          tx = self.new.setup(params)

          # Add important system defined parameters here:
          tx.id                  = generate_key()
          tx.created_at          = Time.now.utc
          tx.status              = "received"
          tx.location            = "PR.gov GMQ"
          tx.state               = :started

          # Pending stuff that we've yet to develop:
          # tx["history"]           = { "received" => { Time.now }}
          # attribute :action, Hash
          # attribute :action_id, Integer
          # attribute :action_description, String
          return tx
      end

      # Loads values from a hash into this object
      # This
      def setup(params, action=nil)
          if params.is_a? Hash
              self.id                         = params["id"]
              self.email                      = params["email"]
              self.ssn                        = params["ssn"]
              self.license_number             = params["license_number"]
              self.first_name                 = params["first_name"]
              self.middle_name                = params["middle_name"]
              self.last_name                  = params["last_name"]
              self.mother_last_name           = params["mother_last_name"]
              self.residency                  = params["residency"]
              self.birth_date                 = params["birth_date"]
              self.reason                     = params["reason"]
              self.IP                         = params["IP"]
              self.system_address             = params["system_address"]
              self.language                   = params["language"]
              self.status                     = params["status"]
              self.location                   = params["location"]
              self.state                      = params["state"]
              self.created_at                 = params["created_at"]
              self.created_by                 = params["created_by"]
              self.updated_at                 = params["updated_at"]
              self.certificate_base64         = params["certificate_base64"]
              self.analyst_fullname           = params["analyst_fullname"]
              self.analyst_id                 = params["analyst_id"]
              self.analyst_approval_datetime  = params["analyst_approval_datetime"]
              self.analyst_transaction_id     = params["analyst_transaction_id"]
              self.analyst_internal_status_id = params["analyst_internal_status_id"]
              self.decision_code              = params["decision_code"]
              self.identity_validated         = params["identity_validated"]
              self.emit_certificate_type      = params["emit_certificate_type"]
              self.certificate_path           = params["certificate_path"]

              # If we had servers in multiple time zones, we'd want
              # to use utc in the next two lines. This might be important
              # if we go cloud in multiple availability zones, since
              # we'll use the Time.now to order transactions.
              self.updated_at                 = Time.now.utc
          end
          return self
      end

      def initialize
          super
          @id = nil
          @email = nil
          @ssn = nil
          @license_number = nil
          @first_name = nil
          @middle_name = nil
          @last_name = nil
          @mother_last_name = nil
          @IP = nil
          @birth_date = nil
          @residency = nil
          @reason = nil
          @language = nil
          @location = nil
          @history = nil
          @state = nil
          @status = nil
          @system_address = nil
          @created_at = nil
          @updated_at = nil
          @created_by = nil
          @certificate_base64 = false
          @analyst_fullname = nil
          @analyst_id = nil
          @analyst_approval_datetime = nil
          @analyst_transaction_id = nil
          @analyst_internal_status_id = nil
          @decision_code = nil
          @identity_validated = nil
          @emit_certificate_type = nil
          @certificate_path = nil
      end

      def to_hash
        # Grab all global global variables in this Object, and turn it into
        # a hash. Should any odd global variable be defined in this object for
        # any other reason than to return the information the API,
        # such as for configuration, that variable will be in this hash, however
        # will not get exposed, due to the Transaction Entity, which is what
        # determines what is exposed via the API. That said, at this time we
        # dont have a single variable that's used for anything other than
        # presenting to the user relevant information. After we return this
        # it'll be filtered by the Transaction Entity.
        # Using this method saves us the work of having to define a to_hash
        # method with every single attribute, everytime it's updated, such as:
        # {
        #   "transaction" => {
        #         "id"               => "#{@id}",
        #         "email"            => "#{@email}",
        #         "ssn"              => "#{@ssn}",
        #           .
        #           .
        #           etc  }
        # }
        # So here we go, let's do some meta-programming magic:
        h =  self.instance_variables.each_with_object({}) { |var,hash|
             hash[var.to_s.delete("@")] = self.instance_variable_get(var) }
        # add any values that aren't variables, but are the result of methods:
        return h
      end

      # Turns a hash into a json object
      def to_json
        to_hash.to_json
      end

      # just an alias in order to have an instance method available
      def ip
        self.IP
      end

      # error count for current state
      def self.current_error_count(id, str=false)
        if(!str)
          return Store.db.get("#{db_id(id)}:errors:current_count")
        elsif(str == "increment")
          return Store.db.incr("#{db_id(id)}:errors:current_count")
        elsif(str == "decrement")
          return Store.db.decr("#{db_id(id)}:errors:current_count")
        elsif(str == "reset")
          return Store.db.set("#{db_id(id)}:errors:current_count", 0)
        else # if anything else is sent:
          false
        end
      end

      def current_error_count
          count = Transaction.current_error_count(self.id)
          count.nil? ? 0 : count.to_i
      end

      # Sets the key prefix for the database.
      def self.db_prefix
        "tx"
      end

      def db_cache_info
        self.id
      end

      # Checks ttl for an id, after a transaction is saved
      # it stores an expiration time.
      # description:
      # gets ttl count for current item
      def ttl()
          Store.db.ttl(db_id)
      end

      def expires
          time_from_now(ttl)
      end


      # Tries to find and setup a transaction object by id.
      def self.find(id)
          # if the record wasn't found
          false if id.nil?

          # Do a multi / exec query:
          # Store.db.multi do
            # find the transaction by the id
            # get the total error count for this item from the error key
            # error_count = self.current_error_count(id)
          # end

          if(!data = Store.db.get(db_id(id)))
            raise ItemNotFound
          else
            begin
              # grab the JSON from this transaction id
              data = JSON.parse(data)
              # set it up into this object's variables
            rescue Exception => e
              raise InvalidNonJsonRecord
            end

            # If no error count found in the db, return 0, else, return count
            # data["current_error_count"] = (error_count.nil? ? 0 : error_count)
            # data["current_error_count"] = (error_count.nil? ? 0 : error_count)
            # Here we instantiate a Transaction object and set it up with data
            return Transaction.new.setup(data)
          end
      end

      # Class method that returns a list of the last transactions in the system
      # TODO: check what this returns when db is empty.
      def self.last_transactions
          Store.db.lrange(Transaction.db_list, 0, -1)
      end

      # a method that creates fake transactions
      # for a massive stress test. This method is available
      # to the admin member group only and is available only
      # to stress test the system. This was necessary in order
      # to perform a GET request that results in the equivalent
      # of a POST in the system. This becomes disabled in production
      # automatically.
      def self.stress_test_save
        # this works only in test and development environments
        if Config.environment == "test" or Config.environment == "development"
            param = JSON.parse('{
            "email":"acolon@ogp.pr.gov",
            "ssn":"111223333",
            "license_number":"123456789",
            "first_name":"Andrés",
            "middle_name":null,
            "last_name":"Colón",
            "mother_last_name":"Pérez",
            "IP":"192.168.1.2",
            "birth_date":"01/01/1982",
            "residency":"San Juan",
            "reason":"STRESS TEST",
            "language":"spanish",
            "location":"PR.gov GMQ",
            "history":null,
            "state":"started",
            "status":"received",
            "system_address":"127.0.0.1",
            "created_at":"2014-08-15T19:50:45.868Z",
            "updated_at":"2014-08-15T19:50:45.868Z",
            "created_by":"***REMOVED***",
            "certificate_base64":null,
            "analyst_fullname":null,
            "analyst_id":null,
            "analyst_approval_datetime":null,
            "analyst_transaction_id":null,
            "analyst_internal_status_id":null,
            "decision_code":null,
            "identity_validated":null,
            "emit_certificate_type":null,
            "certificate_path":null}')
            tx = Transaction.create(param)
            tx.save
            return tx
        else
          # this won't be available when we're
          # not in debug mode.
          raise ResourceNotFound
        end
      end

      def save
        # We have to retrieve this here, incase we ever need values here
        # from the Store. If we do it inside the multi or pipelined
        # we won't have those values availble when building the json
        # and all we'll have is a Redis::Future object. By doing
        # the following to_json call here, we would've retrieved the data
        # needed before the save.
        json = self.to_json

        # do a multi command. Doing multiple commands in an
        # atomic fashion:
        # Store.db.multi do

        pipelined_save(json)
        # sequential_save(json)
        # executed_save(json)

        # puts caller
        debug "#{"Hint".green}: View the transaction data in Redis using: GET #{db_id}\n"+
              "#{"Hint".green}: View the last #{LAST_TRANSACTIONS_TO_KEEP_IN_CACHE} transactions using: "+
              "LRANGE #{db_list} 0 -1\n"+
              "#{"Hint".green}: View the items in pending queue using: LRANGE #{queue_pending} 0 -1\n"+
              "#{"Hint".green}: View the last item in the pending queue using: LINDEX #{queue_pending} 0"
        return true
    end

    # this method is not meant to be called directly, only through save
    def pipelined_save(json)
        debug "Store Pipeline: Attempting to save transaction in Store under key \"#{db_id}\""
        debug "Store Pipeline: Attempting to save into recent transactions list \"#{db_list}\""
        debug "Store Pipeline: Attempting to save into \"#{queue_pending}\" queue"
        Store.db.pipelined do |db_connection|
          # don't worry about an error here, if the db isn't available
          # it'll raise an exception that will be caught by the system
          db_connection.set(db_id, json)

          # If TTL is not nil
          if(EXPIRATION > 0)
            db_connection.expire(db_id, EXPIRATION)
          end

          # Add it to a list of the last couple of items items
          db_connection.lpush(db_list, db_cache_info)
          # trim the items to the maximum allowed, determined by this constant:
          db_connection.ltrim(db_list, 0, LAST_TRANSACTIONS_TO_KEEP_IN_CACHE)

          # Add it to our GMQ pending queue, to be grabbed by our workers
          db_connection.lpush(queue_pending, "#{db_id}:#{Time.now.utc.to_i}")

          # We can't use any method that uses Store.db here
          # because that would cause us to checkout a db connection from the
          # pool for each of those commands; the pipelined commands need to
          # run on the same connection as the commands in the pipeline,
          # so we will not use the Store.add_pending method. For any
          # of our own method that requires access to the db, we will
          # recycle the current db_connection.
          add_pending(db_connection)
        end
        debug "Saved!".bold.green
    end

    # Just a note here that we once tried multi execs but have
    # since decided against it, so we can benefit from twemproxy.
    # twemproxy (nutcracker) doesn't allow multiexecs
    # Pipeline does what we need, anyway, so this is just a note
    # of old code I use as example and we can remove later
    # def multiexec_save(json)
    #   # # We are no longer using multi, as our Storage proxy
    #   # (Twemproxy/Nutcracker) does not support multi/exec. It does support
    #   # pipelining however, so that's what we're using for atomic operations.
    #   # We used to add them by score (time) to a sorted list
    #   # but we can achieve that with a simple list.
    #   # debug "Adding to ordered transaction list: #{db_list}"
    #   # debug "View it using: ZREVRANGE '#{db_list}' 0 -1"
    #   # Store.db.zadd(db_list, updated_at.to_i, db_id)
    #   # # Add to stats:
    #   # # this also does a storage request to update stats
    #   # # increment pending transaction stats
    #   # # When we used to do multi/execs, we'd have this line to run all
    #   # # actions in an atomic fashion like this:
    #   # Store.db.lpush()
    #
    # end

    def executed_save(json)
        # We are no longer using multi, as our Storage proxy
        # (Twemproxy/Nutcracker) does not support multi/exec. It does support
        # pipelining however, so that's what we're using for atomic operations.
        debug "DB-Execute Pipelined: Attempting to save transaction in Store under key \"#{db_id}\""
        debug "DB-Execute Pipelined: Attempting to save into recent transactions list \"#{db_list}\""
        debug "DB-Execute Pipelined: Attempting to save into \"#{queue_pending}\" queue"
        Store.db.execute(true) do |store|
            store.pipelined do
              # don't worry about an error here, if the db isn't available
              # it'll raise an exception that will be caught by the system
              store.set(db_id, json)

              # If TTL is not nil
              if(EXPIRATION > 0)
                store.expire(db_id, EXPIRATION)
              end

              # We used to add them by score (time) to a sorted list
              # but we can achieve that with a simple list.
              # debug "Adding to ordered transaction list: #{db_list}"
              # debug "View it using: ZREVRANGE '#{db_list}' 0 -1"
              # store.zadd(db_list, updated_at.to_i, db_id)

              # Add it to a list of the last couple of items items
              store.lpush(db_list, db_cache_info)
              # trim the items to the maximum allowed, determined by this constant:
              store.ltrim(db_list, 0, LAST_TRANSACTIONS_TO_KEEP_IN_CACHE)

              # Add it to our GMQ pending queue, to be grabbed by our workers
              store.lpush(queue_pending, "#{db_id}:#{Time.now.utc.to_i}")

              # Add to stats:
              # this also does a storage request to update stats
              # increment pending transaction stats
              add_pending

              # When we used to do multi/execs, we'd have this line to run all
              # actions in an atomic fashion like this:
              # store.lpush()
            end
        end
    end

    def sequential_save(json)
        debug "Sequential Request: Attempting to save transaction in Store under key \"#{db_id}\"".bold.red
        debug "Sequential Request: Attempting to save into recent transactions list \"#{db_list}\"".bold.red
        debug "Sequential Request: Attempting to save into \"#{queue_pending}\" queue".bold.red
        Store.db.set(db_id, json)

        # If TTL is not nil
        if(EXPIRATION > 0)
          Store.db.expire(db_id, EXPIRATION)
        end

        # We used to add them by score (time) to a sorted list
        # but we can achieve that with a simple list.
        # debug "Adding to ordered transaction list: #{db_list}"
        # debug "View it using: ZREVRANGE '#{db_list}' 0 -1"
        # Store.db.zadd(db_list, updated_at.to_i, db_id)

        # Add it to a list of the last couple of items items
        Store.db.lpush(db_list, db_cache_info)
        # trim the items to the maximum allowed, determined by this constant:
        Store.db.ltrim(db_list, 0, LAST_TRANSACTIONS_TO_KEEP_IN_CACHE)

        # Add it to our GMQ pending queue, to be grabbed by our workers
        Store.db.lpush(queue_pending, "#{db_id}:#{Time.now.utc.to_i}")
        # Add to stats:
        # this also does a storage request to update stats
        # increment pending transaction stats
        add_pending
   end


      # Called when the transaction's certificate has been generated.
      # in the case of this API it means SIJC's RCI has generated the
      # the certificate
      def certificate_ready(params)
          # validate these parameters. If this passes, we can safely import
          params = validate_certificate_ready_parameters(params)
          # self.certificate_base64          = params["certificate_base64"]
          # to reduce memory usage, we no longer store the base64 cert, we
          # merely mark it as received, and look it up in SIJC's RCI when
          # we're ready to send it via email.
          self.certificate_base64            = true
          self
      end


      # Called when the transaction has completed a manual review
      # in the case of this API, it means an analyst at the PRPD
      # completed a manaul review of a request.
      def review_complete(params)
          # validate these parameters. If this passes, we can safely import.
          params = validate_review_completed_parameters(params)
          self.analyst_id                 = params["analyst_id"]
          self.analyst_fullname           = params["analyst_fullname"]
          self.analyst_approval_datetime  = params["analyst_approval_datetime"]
          self.analyst_transaction_id     = params["analyst_transaction_id"]
          self.analyst_internal_status_id = params["analyst_internal_status_id"]
          self.decision_code              = params["decision_code"]
          self
      end

      # declare our private methods here
      private :pipelined_save, :sequential_save, :executed_save

    end
  end
end

require './app/helpers/transaction_id_factory'

module PRGMQ
  module CAP
    class Transaction < PRGMQ::CAP::Base
      extend Validations
      extend TransactionIdFactory
      include AASM           # use the act as state machine gem
      include LibraryHelper

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
                    :birth_place,          # the place of birth
                    :reason,               # the user's reason for the request
                    :IP,                   # originating IP of the requester as
                                           # claimed/forwarded by client system
                    :system_address,       # the IP of the client system that
                                           # talks to the API
                    :status,               # the status pending proceessing etc
                    :state,                # the state of the State Machine
                    :history,              # A history of all actions performed
                    :location,             # the system that was last assigned the Tx to
                    :created_at,           # creation date
                    :updated_at,           # last update
                    :created_by            # the user that created this

      # Newly created Transactions
      def self.create(params)
          # The expiration is going to be 8 months, in seconds
          # Time To Live - Math:
          # 604800 seconds in a week X 4 weeks = 1 month in seconds
          # 1 month in seconds X 8 = 8 months in seconds.
          ttl =  (604800 * 4) * 8
          # validate all the parameters in the incoming payload
          # throws valid errors if any are detected
          params = validate_transaction_parameters(params)

          tx = self.new
          # Instead of trusting user input, let's extract *exactly* the
          # values from the params hash. This way, additional values
          # that may have been sneaked inside the params hash are ignored
          # safely and never reach the Store.
          tx.id                  = generate_key()
          tx.setup(params)
          # Add important system defined parameters here:
          tx.status              = "received"
          tx.location            = "CAP API DB"
          tx.state               = :started

          # Pending stuff that we've yet to develop:
          # tx["history"]           = { "received" => { Time.now }}
          # attribute :action, Hash
          # attribute :action_id, Integer
          # attribute :action_description, String
          return tx
      end

      # Loads values from a hash into this object
      def setup(params)
          if params.is_a? Hash
              self.email                  = params["email"]
              self.ssn                    = params["ssn"]
              self.license_number         = params["license_number"]
              self.first_name             = params["first_name"]
              self.middle_name            = params["middle_name"]
              self.last_name              = params["last_name"]
              self.mother_last_name       = params["mother_last_name"]
              self.residency              = params["residency"]
              self.birth_date             = params["birth_date"]
              self.birth_place            = params["birth_place"]
              self.reason                 = params["reason"]
              self.IP                     = params["IP"]
              self.system_address         = params["system_address"]
              self.status                 = params["status"]
              self.location               = params["location"]
              self.state                  = params["state"]
              # If we had servers in multiple time zones, we'd want
              # to use utc in the next two lines. This might be important
              # if we go cloud in multiple availability zones, since
              # we'll use the Time.now to order transactions.
              self.created_at             = Time.now.utc
              self.updated_at             = Time.now.utc
              self.created_by             = params["created_by"]
              true
          end
          false
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
          @birth_place = nil
          @residency = nil
          @reason = nil
          @ttl = nil
          @location = nil
          @history = nil
          @state = nil
          @status = nil
          @system_address = nil
          @created_at = nil
          @updated_at = nil
          @created_by = nil
      end

      def to_hash
        {
          "transaction" => {
                "id"               => "#{@id}",
                "email"            => "#{@email}",
                "ssn"              => "#{@ssn}",
                "license_number"   => "#{@license_number}",
                "first_name"       => "#{@first_name}",
                "middle_name"      => "#{@middle_name}",
                "last_name"        => "#{@last_name}",
                "mother_last_name" => "#{@mother_last_name}",
                "IP"               => "#{@IP}",
                "birth_date"       => "#{@birth_date}",
                "birth_place"      => "#{@birth_place}",
                "residency"        => "#{@residency}",
                "reason"           => "#{@reason}",
                "ttl"              => "#{@ttl}",
                "location"         => "#{@location}",
                "history"          => "#{@history}",
                "state"            => "#{@state}",
                "status"           => "#{@status}",
                "system_address"   => "#{@system_address}",
                "created_at"       => "#{@created_at}",
                "updated_at"       => "#{@updated_at}",
                "created_by"       => "#{@created_by}"
          }
        }
      end

      def to_json
        to_hash.to_json
      end

      # error count for current action
      def current_error_count(str=false)
        if(!str.nil?)
          return Store.db.get("#{db_id}:errors:current_count")
        elsif(str == "increment")
          return Store.db.incr("#{db_id}:errors:current_count")
        elsif(str == "decrement")
          return Store.db.decr("#{db_id}:errors:current_count")
        elsif(str == "reset")
          return Store.db.set("#{db_id}:errors:current_count", 0)
        else
          false
        end
      end

      # Sets the key prefix for the database.
      def self.db_prefix
        "tx"
      end

      # ttl count for current item
      def ttl()
          Store.db.ttl(db_id)
      end


      def self.find(id)
          # if the record wasn't found
          false if id.nil?
          puts "Looking in: #{db_id(id)}"
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
            Transaction.new.setup(data)
          end
      end

      def save
        # do a multi command. Doing multiple commands in an
        # atomic fashion:
        Store.db.multi do
          debug "Saving transaction under key '#{db_id}'"
          debug "View it using: GET #{db_id}"
          # don't worry about an error here, if the db isn't available
          # it'll raise an exception that will be caught by the system
          Store.db.set(db_id, self.to_json)

          # We used to add them by score (time) to a sorted list
          # but we can achieve that with a simple list.
          # debug "Adding to ordered transaction list: #{db_list}"
          # debug "View it using: ZREVRANGE '#{db_list}' 0 -1"
          # Store.db.zadd(db_list, updated_at.to_i, db_id)

          # Add it to a list of the last 10 items
          Store.db.lpush(db_list, db_id)
          # trim the items to the last 10
          Store.db.ltrim(db_list, 0, 9)
          # after this line, db.multi runs 'exec', in an atomic fashion
        end
        true
      end

    end
  end
end

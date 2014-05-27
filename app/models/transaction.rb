require './app/helpers/transaction_id_factory'

module PRGMQ
  module CAP
    class Transaction
      extend Validations
      extend TransactionIdFactory
      include AASM           # use the act as state machine gem

      ######################################################
      # A transaction generally consists of the following: #
      ######################################################
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
                    :location              # the system that was last assigned the Tx to

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
          # that may have been sneaking inside the params hash are ignored
          # and never reach the Store.
          tx.id                  = generate_key()
          tx.email               = params["email"]
          tx.ssn                 = params["ssn"]
          tx.license_number      = params["license_number"]
          tx.first_name          = params["first_name"]
          tx.middle_name         = params["middle_name"]
          tx.last_name           = params["last_name"]
          tx.mother_last_name    = params["mother_last_name"]
          tx.residency           = params["residency"]
          tx.birth_date          = params["birth_date"]
          tx.birth_place         = params["birth_place"]
          tx.reason              = params["reason"]
          tx.IP                  = params["IP"]
          tx.system_address      = params["system_address"]
          # Add important system defined parameters here:
          tx.status              = "received"
          tx.location            = "CAP API DB"
          tx.state               = :started

          # Pending stuff that we've yet to develop:
          # tx["history"]           = { "received" => { Time.now }}
          # attribute :action, Hash
          # attribute :action_id, Integer
          # attribute :action_description, String
          puts tx
          return tx
      end

      def tx
        "cap:tx:#{self.id}"
      end

      # error count for current action
      def current_error_count(str=false)
        if(!str.nil?)
          return Store.db.get("#{tx}:errors:current_count")
        elsif(str == "increment")
          return Store.db.incr("#{tx}:errors:current_error_count")
        elsif(str == "decrement")
          return Store.db.decr("#{tx}:errors:current_error_count")
        elsif(str == "reset")
          return Store.db.set("#{tx}:errors:current_error_count", 0)
        else
          false
        end
      end

      # error count for current action
      def ttl()
          Store.db.ttl("#{tx}")
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
                "system_address"       => "#{@system_address}"
          }
        }
      end

      def to_json
        to_hash.to_json
      end

      def save
        # do a multi command. Doing multiple commands in an
        # atomic fashion:
        # Store.db.multi do
          Store.db.set("cap:tx:#{self.id}", self.to_json)
          # "total_error_count"    => "#{@total_error_count}",
          # "current_error_count"  => "#{@current_error_count}"
          return true
        # end
      end

    end
  end
end

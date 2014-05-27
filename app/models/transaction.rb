# Entity Organization as recommended by https://github.com/intridea/grape-entity
module PRGMQ
  module CAP
    class Transaction
      include AASM                       # use the act as state machine gem

      attr_accessor :id,                 # our transaction id
                    :email,              # user email
                    :ssn,                # social security number
                    :license_number,     # valid dtop identification
                    :first_name,         # user's first name
                    :middle_name,        # user's middle name
                    :last_name,          # user's last name
                    :mother_last_name,   # user's maternal last name
                    :residency,          # place of residency
                    :birth_date,         # the date of birth
                    :birth_place,        # the place of birth
                    :reason,             # the user's reason for the request
                    :IP,                 # originating IP of the requester as claimed/forwarded by client system
                    :system_address,     # the IP of the client system that talks to the API
                    :status,             # the status pending, proceessing, etc
                    :state,              # the state of the State Machine
                    :history,            # A history of all actions performed
                    :location,           # the system that was last assigned the Tx to
                    :current_error_count,# error count for current action
                    :total_error_count   # total error count for all action
                    :ttl                 # Time to live before expiring.

      # Newly created Transactions
      def self.create(params)
          # initialize several system defined parameters
          params["status"]               = "received"     # default for new tx
          params["location"]             = "CAP API DB"   # default for new tx
          params["current_error_count"]  = 0
          params["total_error_count"]    = 0
          # The expiration is going to be 8 months, in seconds
          # Time To Live - Math:
          # 604800 seconds in a week X 4 weeks = 1 month in seconds
          # 1 month in seconds X 8 = 8 months in seconds.
          @ttl =  (604800 * 4) * 8
          # validate all the parameters
          validate(params)
      end

      # validates a given value, returns error if nil
      def validate(params)
        raise MissingEmail           if params("email").nil?
        raise MissingSSN             if params["ssn"].nil?
        raise MissingLicenseNumber   if params["license_number"].nil?
        raise MissingFirstName       if params["first_name"].nil?
        raise MissingLastName        if params["last_name"].nil?
        raise MissingResidency       if params["residency"].nil?
        raise MissingBirthDate       if params["birth_date"].nil?
        raise MissingClientIP        if params["IP"].nil?
        raise MissingReason          if params["reason"].nil?
        raise MissingStatus          if params["status"].nil?

        raise InvalidEmail           if params("email").nil?
        raise MissingSSN             if params["ssn"].nil?
        raise MissingLicenseNumber   if params["license_number"].nil?
        raise MissingFirstName       if params["first_name"].nil?
        raise MissingLastName        if params["last_name"].nil?
        raise MissingResidency       if params["residency"].nil?
        raise MissingBirthDate       if params["birth_date"].nil?
        raise MissingClientIP        if params["IP"].nil?

      end


      # The following are System Attributes
      attribute :system_address, String   # the IP of the proxy system that talks to the API
      attribute :status, String           # the status pending, proceessing, etc
      attribute :state, String, :default => "received"         # the state of the State Machine
      attribute :history, Hash            # A history of all actions performed
      attribute :location, String         # the system that currenty has the Tx
      attribute :current_error_count, Integer, :default => 0 # error count for current action
      attribute :total_error_count, Integer,   :default => 0   # total error count for all action
      # attribute :action, Hash
      # attribute :action_id, Integer
      # attribute :action_description, String

    end
  end
end

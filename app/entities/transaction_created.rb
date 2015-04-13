# Entities: This is used by the Grape API to expose models.
# We use a custom entity for when we want to present only specific
# information for a specific action.
# We could in theory do all of those checks using one entity, but due to the
# amount of different actions and users we have, the code wouldn't be
# easy to read. So, for your viewing pleasure and ease of maintenance
# we use different entities for different actions.
# There's always the transactions.rb, which presents all the information
# and we could use it as a default.

# This is the entity for newly created transactions
module PRGMQ
  module CAP
    module Entities
      class TransactionCreated < Grape::Entity
        expose :id, documentation:    { type: String, desc: "Transaction id." }
        # # User Information
        expose :email, documentation: { type: String, desc: "Email address" }
        expose :ssn, documentation: { type: String, desc: "Social Security Number"}
        expose :passport, documentation: { type: String, desc: "Passport Number"}                
        expose :license_number, documentation: { type: String, desc: "DTOP identification number"}
        expose :first_name, documentation: { type: String, desc: "First name"}
        expose :middle_name, documentation: { type: String, desc: "Middle name"}
        expose :last_name, documentation: { type: String, desc: "Last name"}
        expose :mother_last_name, documentation: { type: String, desc: "Maternal last name"}
        expose :residency, documentation: { type: String, desc: "Current place of residency" }
        expose :birth_date, documentation: { type: Date, desc: "Date of birth"}
        expose :reason, documentation: { type: Date, desc: "Reason for Certificate Request"}
        expose :language, documentation: { type: String, desc: "User requested language of "+
                                                       "interest for notifications."}
        expose :IP, documentation: { type: String, desc: "Client's IP address"}
        # # Status Information
        expose :status, documentation: { type: String, desc: "Status identification"}
        # Transaction State Machine Information:
        expose :state, documentation: { type: String, desc: "Transaction State." }
        expose :current_error_count
        expose :created_at
        expose :updated_at
        expose :created_by
        expose :location
        expose :ttl, documentation: { type: Date, desc: "Time in seconds for record to expire."}
        expose :expires, documentation: { type: Date, desc: "Human readable expiration time."}
      end
    end
  end
end

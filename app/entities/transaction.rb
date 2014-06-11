# Entities: This is used by the Grape API to expose models.
# In theory we could embed these entities in the model itself
# in order to organize our entitties better underneath the model
# they represent. We'd do this by creating a method in the model, like this:
# Class Transaction
#   def entity
#     CAP::Entities::Transaction
#   end
# end
# However, while this makes the API look cleaner, it also makes it
# more ambigous when reading the api.rb code. For this reason,
# entities are explictly defined using the 'with' option when we
# present a model using Grape.
module PRGMQ
  module CAP
    module Entities
      class Transaction < Grape::Entity
        # expose :id, if: { type: :hi }, documentation:    { type: String, desc: "Transaction id." }
        expose :id, documentation:    { type: String, desc: "Transaction id." }
        # # User Information
        expose :email, documentation: { type: String, desc: "Email address" }
        expose :ssn, documentation: { type: String, desc: "Social Security Number"}
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
        expose :certificate_base64, documentation: { type: String, desc: "Base64 Certificate"}
        expose :analyst_fullname, documentation: { type: String,
               desc: "The full name of the PRPD analyst in the DB."}
        expose :analyst_id, documentation: { type: String,
               desc: "The id of the user of the PRPD analyst in the ANPE db."}
        expose :analyst_approval_datetime, documentation: { type: String,
               desc: "The date in UTC format when an analyst approved this "+
                     "action in PRPD"}
        expose :analyst_transaction_id, documentation: { type: String,
               desc: "The internal ANPE Id for this transaction."}
        expose :analyst_internal_status_id, documentation: { type: String,
               desc: "The internal ANPE status code assigned by an analyst to "+
               "perform this action on this transaction."}
        expose :decision_code, documentation: { type: String,
               desc: "The decision code expected by our GMQ CAP API "+
                     "for the analyst decision regarding whether we should "+
                     "emit a positive certificate or not, for this manually "+
                     "reviewed request at PRPD."}
        # # Status Information
        expose :status, documentation: { type: String, desc: "Status identification"}
        # Transaction State Machine Information:
        expose :state, documentation: { type: String, desc: "Transaction State." }
        expose :current_error_count
        expose :created_at
        expose :updated_at
        expose :created_by
        expose :location
        # expose :total_error_count
        # expose :action do
        #     expose :action_id
        #     expose :action_description
        # end
        # expose :history, using: PRGMQ::CAP::API
        # expose :location, documentation: { type: String, desc: "Last known location "+
                                                              #  "of the transaction"}

        # expose :text, documentation: { type: "string", desc: "Status update text." }
        # expose :ip, if: { type: :full }
        # expose :user_type, user_id, if: lambda { |status, options| status.user.public? }
        # expose :digest { |status, options| Digest::MD5.hexdigest(status.txt) }
        # expose :replies, using: API::Status, as: :replies
      end
    end
  end
end

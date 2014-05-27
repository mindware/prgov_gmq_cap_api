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
        expose :birth_place, documentation: { type: Date, desc: "Place of birth"}
        expose :reason, documentation: { type: Date, desc: "Reason for Certificate Request"}
        expose :IP, documentation: { type: String, desc: "Client's IP address"}
        # # Status Information
        expose :status, documentation: { type: String, desc: "Status identification"}
        # Transaction State Machine Information:
        expose :state, documentation: { type: String, desc: "Transaction State." }
        expose :current_error_count
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

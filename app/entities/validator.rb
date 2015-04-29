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
      class Validator < Grape::Entity

        expose :id, documentation:    { type: String, desc: "Request id." }
        expose :tx_id, documentation:    { type: String, desc: "Transaction id." }
        # # User Information
        expose :ssn, documentation: { type: String, desc: "Social Security Number"}
        expose :passport, documentation: { type: String, desc: "Passport Number"}
        expose :IP, documentation: { type: String, desc: "Client's IP address"}
        expose :certificate_base64, documentation: { type: String, desc: "Base64 Certificate"}
        # # Status Information
        expose :result, documentation: { type: String, desc: "The result from the remote system regarding the validation"}
        expose :status, documentation: { type: String, desc: "Status identification for the request"}
        expose :created_at
        expose :updated_at
        expose :created_by
        expose :location, documentation: { type: Date, desc: "Last system responsible for this item."}
        expose :ttl, documentation: { type: Date, desc: "Time in seconds for record to expire."}
        expose :expires, documentation: { type: Date, desc: "Human readable expiration time."}
        expose :error_count
        expose :last_error_type
        expose :last_error_date
      end
    end
  end
end

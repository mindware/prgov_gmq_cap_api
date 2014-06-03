require '../rest'

require 'base64'

user = "***REMOVED***"
pass = "***REMOVED***"
id = '1e29234ee0c84921adec08fbe5980162'
url = "http://localhost:9000/v1/cap/transaction/review_complete"

analyst_internal_status_id      = "030" # the action's id in the system
analyst_id 		                 = "123" # the id of the user in the db
analyst_fullname	              = "Walter Lamela"
analyst_transaction_id 		     = "analyst12345" # the id of the record in the db
approval_date      	           = Time.now.utc
decision           		         = "100"

payload = {
              "id" => id,
              "decision_code" => decision,
      	      "analyst_id"    => analyst_id,
      	      "analyst_fullname" => analyst_fullname,
              "analyst_internal_status_id" => analyst_internal_status_id,
              "analyst_transaction_id" => analyst_transaction_id,
              "analyst_approval_datetime" => approval_date
          }
method = "put"
type = "json"

a = Rest.new(url, user, pass, type, payload, method)
a.request

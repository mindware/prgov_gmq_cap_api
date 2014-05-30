require '../rest'

require 'base64'

user = "***REMOVED***"
pass = "***REMOVED***"
id = '1e29234ee0c84921adec08fbe5980162'
url = "http://localhost:9000/v1/cap/transaction/review_complete"
anpe_action_id      = "030"
anpe_transaction_id = "anpe12345"
approval_date       = Time.now.utc
decision            = "100"

payload = {
              "id" => id,
              "decision_code" => decision,
              "analyst_internal_status_id" => anpe_action_id,
              "analyst_transaction_id" => anpe_transaction_id,
              "analyst_approval_datetime" => approval_date
          }
method = "put"
type = "json"

a = Rest.new(url, user, pass, type, payload, method)
a.request

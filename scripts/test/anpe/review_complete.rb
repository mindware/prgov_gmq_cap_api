require '../rest'

require 'base64'

user = "***REMOVED***"
pass = "***REMOVED***"

url = "http://localhost:9000/v1/cap/transaction/certificate_ready"
# payload = JSON.parse('{"first_name" : "Andrés", "last_name" : "Colón",
#             "mother_last_name" : "Pérez", "ssn" : "111-22-3333",
#             "license" : "12345678", "birth_date" : "01/01/1982",
#             "residency" : "San Juan", "IP" : "192.168.1.2",
#             "reason" : "Solicitud de Empleo", "birth_place" : "San Juan",
#             "email" : "acolon@ogp.pr.gov", "license_number" : "1234567"}')
id = '1e29234ee0c84921adec08fbe5980162'
# file = File.open("./sample/sagan.jpg", "rb")
# contents = file.read
# cert64 = Base64.strict_encode64(contents)
# payload = { "id" => id,
#             "certificate_base64" => cert64 }

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

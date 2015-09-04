require '../lib/rest'

require 'base64'

user = "user"
pass = "password"

url = "http://localhost:9000/v1/cap/transaction/certificate_ready"
# payload = JSON.parse('{"first_name" : "Andrés", "last_name" : "Colón",
#             "mother_last_name" : "Pérez", "ssn" : "111-22-3333",
#             "license" : "12345678", "birth_date" : "01/01/1982",
#             "residency" : "San Juan", "IP" : "192.168.1.2",
#             "reason" : "Solicitud de Empleo", "birth_place" : "San Juan",
#             "email" : "acolon@ogp.pr.gov", "license_number" : "1234567"}')
#file = File.open("./sample/sagan.jpg", "rb")
file = File.open("./sample/cert.base64", "rb")
#contents = file.read
cert64 = file.read.strip
#cert64 = Base64.strict_encode64(contents)
# Grab the id from the params, otherwise us an id that may or may not exist.
if ARGV[0].to_s != ""
	id = ARGV[0]
else
	id = '0338ca35444694f18a'
end
payload = { "id" => id,
            "certificate_base64" => cert64 }
method = "put"
type = "json"

a = Rest.new(url, user, pass, type, payload, method)
a.request

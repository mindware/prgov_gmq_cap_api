require '../rest'
user = "***REMOVED***"
pass = "***REMOVED***"
# credentials via basic auth
url = "http://localhost:9000/v1/cap/transaction/"
payload = JSON.parse('{"first_name" : "Andrés", "last_name" : "Colón",
            "mother_last_name" : "Pérez", "ssn" : "111-22-3333",
            "license" : "12345678", "birth_date" : "01/01/1982",
            "residency" : "San Juan", "IP" : "192.168.1.2",
            "reason" : "Solicitud de Empleo", "birth_place" : "San Juan",
            "email" : "acolon@ogp.pr.gov", "license_number" : "1234567"}')
method = "post"
type = "json"

a = Rest.new(url, user, pass, type, payload, method)
a.request

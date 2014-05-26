require 'json'
require 'rest_client'
require 'grape'
# include all helpers
Dir["../../app/helpers/*.rb"].each {|file| require file }

include PRGMQ::CAP::LibraryHelper	# General Helper Methods

user = "***REMOVED***"
pass = "***REMOVED***"
# credentials via basic auth
u = "#{user}:#{pass}@"
payload = JSON.parse('{"first_name" : "Andrés", "last_name" : "Colón",
            "mother_last_name" : "Pérez", "ssn" : "111-22-3333",
            "license" : "12345678", "birth_date" : "01/01/1982",
            "residency" : "San Juan", "IP" : "192.168.1.2",
            "reason" : "Because I can", "birth_place" : "San Juan",
            "email" : "its@me.mario", "license_number" : "1234567"}')



def request(payload, credentials)
  response = RestClient.post "http://#{credentials}localhost:9000/v1/cap/transaction/", payload.to_json, :content_type => :json, :accept => :json
end


def res(r)
  puts "HTTP Code: #{r.code}"
  puts "Headers: #{r.headers}"
  puts "Result:\n#{r.to_str}"
end


begin
  result = request(payload, u)
  res result
rescue Exception => e
  puts e.inspect.to_s
end

require 'json'
require 'rest_client'
require 'grape'
# include all helpers
Dir["../../app/helpers/*.rb"].each {|file| require file }

include PRGMQ::CAP::LibraryHelper	# General Helper Methods

class Rest

  attr_accessor :user, :pass, :credentials, :url, :payload, :method, :type

  def to_curl
    str = "curl "
    str << "-u #{user}:#{pass} " if !user.nil? and !pass.nil?
    str << '-H "Content-Type: application/json" ' if type.to_s == "json"
    str << "-d '#{payload.to_json}' " if payload.to_s.length > 0
    str << "-X "
    str << "POST "    if method.to_s == "post"
    str << "GET "     if method.to_s == "get"
    str << "DELETE "  if method.to_s == "delete"
    str << url
  end

  def request
     begin
         site =  url.gsub("https://", "https://#{credentials}@")
         site = site.gsub("http://", "http://#{credentials}@")
         response = RestClient.post site, payload.to_json,
                                          :content_type => :json,
                                          :accept => :json
         puts "URL:\n#{site}\n\n"
         puts "CURL:\n#{self.to_curl}\n\n"
         puts "Requested:\n#{payload.to_json}\n\n"
         puts "HTTP Code:\n#{response.code}\n\n"
         puts "Headers:\n#{response.headers}\n\n"
         puts "Result:\n#{response.gsub(",", ",\n").to_str}\n"
     rescue Exception => e
         puts e.inspect.to_s
     end
  end

  def initialize(url, user, pass, type, payload, method)
     @user = user
     @pass = pass
     @credentials = "#{user}:#{pass}"
     @url = url
     @payload = payload
     @method = method
     @type = type
  end

end

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

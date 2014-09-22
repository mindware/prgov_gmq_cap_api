require '../lib/rest'

def setup
user = ENV["API_USER"]
pass = ENV["API_PASSWORD"]
# credentials via basic auth
url = "http://localhost:9000/v1/cap/transaction/"
first_name = ENV["FUZZY_NAME"]
last_name  = ENV["FUZZY_LASTNAME"]
mother_last_name = ENV["FUZZY_MOTHER_LASTNAME"] 
ssn = ENV["FUZZY_SSN"]
license = ENV["FUZZY_LICENSE"] 
birth_date = ENV["FUZZY_BIRTH_DATE"]  
residency  = ENV["FUZZY_RESIDENCY"]
ip = '192.168.1.2'
reason = 'Background check to join S.H.I.E.L.D.'
birth_place = ENV["FUZZY_BIRTH_PLACE"]
#birth_place = "398174400000"
email = ENV["FUZZY_EMAIL"]
# Test it in english and spanish. Comment last one to try the other.
language = 'english'
language = 'spanish'

#first_name << (rand(500) + rand(500)).to_s 
payload = { 
		:first_name => first_name,
		:last_name  => last_name,
		:mother_last_name => mother_last_name,
		:ssn	=> ssn,
		:license_number => license,
		:birth_date => birth_date,
		:residency  => residency,
		:IP	    => ip,
		:reason	    => reason,
		:birth_place=> birth_place,
		:email	    => email,
		:language   => language
	 }
method = "post"
type = "json"

a = Rest.new(url, user, pass, type, payload, method)
a.request
end
total = 0
(0..total).each do |i|
	setup()
end
puts "Done! (#{total} added)"

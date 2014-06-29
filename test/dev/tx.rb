require 'workflow'
class Transaction
	include Workflow

	workflow do
		state :new do 
			event :prgov_received, :transition_to => :send_prgov_email
		end

		state :send_prgov_email do 	
			event :sending_prgov_email, :transition_to => :sent_prgov_email
		end

		state :sent_prgov_email do 
			event :validate_with_sijc, :transition_to =>  
		end
	end
end

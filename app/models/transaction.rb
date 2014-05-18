# Entity Organization as recommended by https://github.com/intridea/grape-entity
module PRGMQ
  module CAP
    class Transaction

      attr_accessor :id,
                    :email, :ssn, :license_number, :first_name, :last_name,
                    :residency, :birth_date, :IP, :status, :history, :location,
                    :current_error_count, :total_error_count,
                    :action, :action_id, :action_description

      def initialize
        self.id = "42"
        self.email = "its@me.mario"
      end

    end
  end
end

require 'moneta'
require 'toystore'
require 'adapter/memory'
require './app/models/transaction_id_factory'

# Entity Organization as recommended by https://github.com/intridea/grape-entity
module PRGMQ
  module CAP
    class Transaction
      include AASM                       # use the act as state machine gem
      include Toy::Store                 # This wraps Moneta and Toy::Object
      key TransactionIdFactory.new       # Our Id Factory for Unique Ids

      adapter :memory, PRGMQ::CAP::Storage.db() # we pool our connections

      validates_presence_of :email
      validates_presence_of :ssn
      validates_presence_of :license_number
      validates_presence_of :first_name
      validates_presence_of :last_name
      validates_presence_of :residency
      validates_presence_of :birth_date
      validates_presence_of :IP

      attribute :id, String               # our transaction id
      # The following are User Request Attributes
      attribute :email, String            # user email
      attribute :ssn, String              # social security number
      attribute :license_number, String   # valid dtop identification
      attribute :first_name, String       # user's first name
      attribute :middle_name, String      # middle first name
      attribute :last_name, String        # user's last name
      attribute :mother_last_name, String # user's last name
      attribute :residency, String        # place of residency, user defined
      attribute :birth_date, String       # the date of birth
      attribute :birth_place, String      # the place of birth
      attribute :reason, String           # the reason for the request
      attribute :IP, String               # the originating IP of the requester

      # The following are System Attributes
      attribute :system_address, String   # the IP of the proxy system that talks to the API
      attribute :status, String           # the status pending, proceessing, etc
      attribute :state, String, :default => "received"         # the state of the State Machine
      attribute :history, Hash            # A history of all actions performed
      attribute :location, String         # the system that currenty has the Tx
      attribute :current_error_count, Integer, :default => 0 # error count for current action
      attribute :total_error_count, Integer,   :default => 0   # total error count for all action
      # attribute :action, Hash
      # attribute :action_id, Integer
      # attribute :action_description, String

      # We'd use this if we wanted to be lazy on the api definition
      # and not have to include with: <entityName>. I've opted for
      # not being ambigous, so that if someone reads the api.rb code
      # they'll get a sense of what's happening. I leave this here
      # just as a note to myself that this is possible and a reminder
      # that while magic is awesome, understanding the science behind it is
      # far more important when it comes to code. Take this comment
      # as a carving in the code trunk that spells out a 'no to ambiguity'.
      # def entity
      #   CAP::Entities::Transaction.new(self)
      # end

    end
  end
end

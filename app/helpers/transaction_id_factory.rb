require 'securerandom'

require 'rubyflake'

module PRGMQ
  module CAP
    module TransactionIdFactory

      # To be appended to all certificates requested through
      # this PRGOV service.
      # SERVICE_ID Convention:
      # First two letters represents agency/organization/platform
      # (PR == PR.gov)
      # The next three characters reprents the related API (ie CAP)
      # So this means that this is a certificate of the PR service that
      # is validated with the CAP API.
      SERVICE_ID = "PRCAP"

      # the transaction list will always have the same name
      # this is used for certificate transactions
      def generate_key
        TransactionIdFactory.generate_key
      end

      # Checks the length of our keys. We simply generate one
      # to check. Used by the Validations helper
      def transaction_key_length
         TransactionIdFactory.generate_key.length
      end

      # use our class method to generate an id
      # these are used for other generic services that require
      # a unique id. It does not include a service identifier.
      def generate_random_id
          TransactionIdFactory.generate_random_id
      end

      # use our class method to generate an id and check for length
      def random_id_length
          TransactionIdFactory.generate_random_id.length
      end

      # Checks the length of our keys. We simply generate one
      # to check. Used by the Validations helper
      def self.transaction_key_length
         self.generate_key.length
      end

      # checks the length of our random ids
      def random_id_length
          self.generate_random_id.length
      end

      # Generate a random string with an appended
      # service identifier.
      def self.generate_key
        # change this later for snow flake.
        # Always use 0 at the start.
        #  000-000-id
        # [000] = agency
        #  xxx-[000] = API system that can validate
        #  PRG-001-&qerqwer0qerqe
        # "0" + SecureRandom.uuid.gsub("-", "").to_s #[0..16]
        "#{self.service_id}" + self.generate_flake
      end

      # Generates a random string.
      # used for transaction ids as well as
      # other types of ids, such as random ids that
      # don't require an service identifier (ie validation requests)
      def self.generate_random_id
        return SecureRandom.uuid.gsub("-", "").to_s
      end

      # Generates a 64-bit ID.
      # Safe to use in a distributed fashion.
      def self.generate_flake
        return Rubyflake.generate.to_s
      end

      # A method that returns the service_id constant value.
      def self.service_id
        return SERVICE_ID
      end

      # RCI's service_id. TODO: ask RCI to update their service_id to something
      # decent, such as RCCAP
      def self.rci_service_id
        return "1"
      end

      # RCI's transaction length. TODO: use the actual length
      def self.rci_transaction_key_length
        return 5
      end

    end
  end
end

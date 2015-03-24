require 'securerandom'

require 'rubyflake'

module PRGMQ
  module CAP
    module TransactionIdFactory

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
        "PRGCAP" + self.generate_flake
      end

      # Generates a random string.
      # used for transaction ids as well as
      # other types of ids, such as random ids that
      # don't require an service identifier (ie validation requests)
      def self.generate_random_id
        return SecureRandom.uuid.gsub("-", "").to_s
      end

      # Generates a 64-bit ID.
      # Safe to distribute.
      def self.generate_flake
        return Rubyflake.generate.to_s
      end

    end
  end
end

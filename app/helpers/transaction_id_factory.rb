require 'securerandom'

module PRGMQ
  module CAP
    module TransactionIdFactory

      # the transaction list will always have the same name
      def generate_key
        TransactionIdFactory.generate_key
      end

      # Checks the length of our keys. We simply generate one
      # to check. Used by the Validations helper
      def transaction_key_length
         TransactionIdFactory.generate_key.length
      end

      # Checks the length of our keys. We simply generate one
      # to check. Used by the Validations helper
      def self.transaction_key_length
         self.generate_key.length
      end

      def self.generate_key
        SecureRandom.uuid.gsub("-", "")
      end

    end
  end
end

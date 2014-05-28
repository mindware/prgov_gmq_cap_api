require 'securerandom'

module PRGMQ
  module CAP
    module TransactionIdFactory 

      # the transaction list will always have the same name
      def generate_key
        SecureRandom.uuid.gsub("-", "")
      end
    end
  end
end

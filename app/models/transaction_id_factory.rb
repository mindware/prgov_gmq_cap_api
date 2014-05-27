require 'securerandom'

module PRGMQ
  module CAP
    class TransactionIdFactory < Toy::Identity::AbstractKeyFactory

      # the transaction list will always have the same name
      def generate_key
        SecureRandom.uuid
      end
    end
  end
end

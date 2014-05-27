require 'securerandom'

module PRGMQ
  module CAP
    class TransactionIdFactory < Toy::Identity::AbstractKeyFactory
      # How should the id be typecast
      def key_type
        String
      end

      # the transaction list will always have the same name
      def next_key(object)
      end
    end
  end
end

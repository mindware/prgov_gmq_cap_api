module PRGMQ
  module CAP
    module StorageHelper
      #
      def redis
        @redis ||= Redis.new
      end

    end
  end
end

module PRGMQ
  module CAP
    class Stats

      def self.db_prefix
        "stats"
      end

      # ie: get get gmq:cap:stats:visits
      def self.visits_prefix
        "visits"
      end

      def self.db_id
        "#{Store.db_prefix}:#{db_prefix}"
      end

      def self.new_request
        Store.db.incr("#{db_id}:#{visits_prefix}")
      end

      def self.visits
        Store.db.get("#{db_id}:#{visits_prefix}")
      end

    end
  end
end

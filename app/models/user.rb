module PRGMQ
  module CAP
    class User
        attr_reader :name, :groups

        def initialize(name, groups)
          error!(InvalidAccess.data,  InvalidAccess.http_code) if groups.class != Array
          @name = name
          # By default, always add the 'all' group.
          # This group doesn't need to be stored in the server, since
          # all users belong to it, always.
          @groups = groups
          @groups.push "all"
        end

    end
  end
end

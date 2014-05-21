module PRGMQ
  module CAP
    class User
        attr_reader :name, :groups

        def initialize(name, groups)
          raise InvalidUserGroup if groups.class != Array
          # if for some reason a user wasn't configured with a proper
          # group, we delete whatever it is that was stored and
          # setup the group properly. - Nevermind, we'll error out.
          # if(groups.class != Array)
          #    groups = []
          # end
          @name = name
          # By default, always add the 'all' group.
          # This group doesn't need to be stored in the server, since
          # all users belong to it, always.
          @groups = groups
          @groups.push "all" unless @groups.include? "all"
        end

    end
  end
end

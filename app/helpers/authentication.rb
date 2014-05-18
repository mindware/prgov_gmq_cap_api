module PRGMQ
  module CAP
    class Authentication

        def self.valid?(username=nil, password=nil)
            return false if(username.to_s.length == "" or password.to_s.length == "")
            # We'll have to change this in the future so that we actually authenticate
            # against some system

            #### CHANGE THIS INTEGRATE REDIS
            # if redis is down, return peropr error:
            #
            # Redis.get_record(user) if Redis.record_exists(username, password)
            # when succcessful, return the user and their access
            # (ie: web, policia, sijc, admin):
            if((username == "andres" or username == "policia") and password == "password")
              return true
            else
              return false
            end
        end

        # Finds a user by name.
        # Since Grape can't store the credentials when it delegates
        # basic authentication to Rack, we must do this find here.
        # If we ever figure out how to save a result from the initial
        # http_basic, ie, by modifying the self.valid? method above
        # to return the User object, then we should simply send such
        # an object as a parameter to the following method. Unfortunately
        # perhaps as a result of lack of sleep, I haven't figured it out
        # in the last few hours (after 17 hours of straight coding) how to
        # do this safely taking into consideration we're running on Goliath
        # and there are fibers all over the place. Sue me. If you attempt it
        # please, don't step on the fibers. Thanks.
        def self.find_user(username=nil)
            return false if(username.to_s.length == "")
            # Fetch user
            #### CHANGE THIS INTEGRATE REDIS
            groups = ["admin"] if(username == "andres")
            groups = ["policia"] if(username == "policia")
            return User.new(username, groups)
        end

    end
  end
end

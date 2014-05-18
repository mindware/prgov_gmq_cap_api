module PRGMQ
  module CAP
    # Base Error, our Internal Server Error.
    class AppError < RuntimeError
      # data is the method used to return hashes with http and app errors.
      def self.data
        # sprinkle some errors and print the Exception name with self.to_s
        {"error" => { "http_error" => "An error ocurred",
                      "http_code" => 500,
                      "app_error" => "An unexpected internal error "+
                                     "has occurred.",
                      "app_code" => 6000,
                      "exception" => "#{self.to_s}"
                    }
        }
      end
      # This method is used to retrieve the http error code.
      def self.http_code
          #+ Add logging capability here.
          self.data["error"]["http_code"]
      end
    end

    class InvalidURL < RuntimeError; end

    class InvalidCredentials < PRGMQ::CAP::AppError
      def self.data
        { "error" => { "http_error" => "401 Unauthorized",
                       "http_code" => 401,
                       "app_error" => "Unauthorized: Username or "+
                                     "password is incorrect.",
                       "app_code" => 4000,
                       "exception" => "#{self.to_s}"
                    }
        }
      end
    end

    class InvalidAccess < PRGMQ::CAP::AppError
      def self.data
        { "error" => {  "http_error" => "403 Unauthorized",
                        "http_code" => 403 ,
                        "app_error" => "Forbidden: Your credentials do"+
                        " not allow you access to that resource.",
                        "app_code" => 4500,
                        "exception" => "#{self.to_s}"
                    }
        }
      end
    end

    class InvalidAccessGroup < PRGMQ::CAP::AppError
      def self.data
        { "error" => { "http_message" => "500 Unauthorized",
                       "http_code" => 500,
                       "app_error"  => "nternal Server Error: The user has an "+
                       "improperly configured access group in the database. "+
                       "The administrator needs to set a proper array as a "+
                       "data structure for the access group.,
                       "app_code" => 6001,
                       "exception" => "#{self.to_s}"
                    }
        }
      end
    end

    class InvalidAccessGroup < PRGMQ::CAP::AppError
      def self.data
        { "error" => { "http_message" => "500 Unauthorized",
                       "http_code" => 500,
                       "app_error"  => "The user has an invalid access"+
                                    " group. The user database needs a proper "+
                                    "array as a data structure for the access "+
                                    "group.",
                       "app_code" => 6001,
                       "exception" => "#{self.to_s}"
                    }
        }
      end
    end

  end
end

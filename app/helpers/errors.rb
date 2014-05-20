module PRGMQ
  module CAP

    # trap all thrown Exception and fail gracefuly with a
    # 500 and a proper message. This is done when something breaks in the
    # code, and when basically it grabs any unexpected errors. All expected
    # errors are not caught by this middleware, but instead, use the proper
    # "error!"" methods of Grape (most of those are found in the Helper
    # Library (./helpers/library.rb)
    class ApiErrorHandler < Grape::Middleware::Base
      def call!(env)
        @env = env
        begin
          @app.call(@env)
        rescue Exception => e
          # Prepare the JSON error message.

          # if this is one of our AppErrors, grab the custom error message.
          # Store the class name as klass, so that we may call the proper
          # http_code later on.
          #throw :error, :message => (e.class.data), :status => 500
          #exit
          if e.is_a? AppError
            message = e.class.data
            klass = e.class
          else
            # For all other exceptions, use our generic error
            message = AppError.data
            klass = AppError
          end
          # Sprinkle some additonal data if we're in development mode.
          if Goliath.env.to_s == "development"
            # Add additional exception message, which will contain more
            # information if this is a system exception transformed into
            # AppError. We'll skip this if it's just a child of AppError,
            # since it wont contain new information like it does for
            # other exceptions.
            if klass == AppError
              message["error"]["app_exception_error"]       = e.message
            end

            # Add the name of the exception to all errors.
            message["error"]["app_exception"] = "#{self.to_s}"

            if(PRGMQ::CAP::Config.backtrace_errors)
              # Provide a full backtrace:
              message["error"]["app_exception_backtrace"] = e.backtrace
            else
              # Provide a full backtrace:
              message["error"]["app_exception_line"] = e.backtrace[0]
            end
          end
          throw :error, :message => message, :status => klass.http_code
        end
      end
    end

    # Base Error, our Internal Server Error.
    class AppError < RuntimeError
      # data is the method used to return hashes with http and app errors.
      def self.data
        # sprinkle some errors and print the Exception name with self.to_s
        {"error" => { "http_error" => "An Internal Server Error ocurred",
                      "http_code" => 500,
                      "app_error" => "An unexpected internal error "+
                                     "has occurred.",
                      "app_code" => 6000
                    }
        }
      end
      # This method is used to retrieve the http error code.
      def self.http_code
          #+ Add logging capability here.
          self.data["error"]["http_code"]
      end

      def self.message
          self.data["error"][""]
      end
    end

    class InvalidURL < RuntimeError; end

    class InvalidCredentials < PRGMQ::CAP::AppError
      def self.data
        { "error" => { "http_error" => "401 Unauthorized",
                       "http_code" => 401,
                       "app_error" => "Unauthorized: Username or "+
                                     "password is incorrect.",
                       "app_code" => 4000
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
                        "app_code" => 4500
                    }
        }
      end
    end

    class InvalidAccessGroup < PRGMQ::CAP::AppError
      def self.data
        { "error" => { "http_message" => "500 Internal Server Error",
                       "http_code" => 500,
                       "app_error"  => "Internal Server Error: The user has an "+
                       "improperly configured access group. "+
                       "The administrator needs to set a proper array as a "+
                       "data structure for the access group.",
                       "app_code" => 6001
                    }
        }
      end
    end

    class InvalidAccessGroup < PRGMQ::CAP::AppError
      def self.data
        { "error" => { "http_message" => "500 Internal Server Error",
                       "http_code" => 500,
                       "app_error"  => "The user has an invalid access"+
                                    " group. The user database needs a proper "+
                                    "array as a data structure for the access "+
                                    "group.",
                       "app_code" => 6001
                    }
        }
      end
    end

    class MissingConfigFile < PRGMQ::CAP::AppError
      def self.data
        { "error" => { "http_message" => "500 Internal Server Error",
                       "http_code" => 500,
                       "app_error"  => "The configuration could not be read.",
                       "app_code" => 6002
                    }
        }
      end
    end

    class InvalidConfigFile < PRGMQ::CAP::AppError
      def self.data
        { "error" => { "http_message" => "500 Internal Server Error",
                       "http_code" => 500,
                       "app_error"  => "The API's configuration file is invalid "+
                                       "and could not be parsed.",
                       "app_code" => 6003
                    }
        }
      end
    end

    class InvalidUserGroup < PRGMQ::CAP::AppError
      def self.data
        { "error" => { "http_message" => "500 Internal Server Error",
                       "http_code" => 500,
                       "app_error"  => "The user's config has an invalid or "+
                                       "missing security group.",
                       "app_code" => 6004
                    }
        }
      end
    end

    class InvalidPasskeyLength < PRGMQ::CAP::AppError
      def self.data
        { "error" => { "http_message" => "500 Internal Server Error",
                       "http_code" => 500,
                       "app_error"  => "The system configured passkey for "+
                                    "the user is of an invalid length.",
                       "app_code" => 6005
                    }
        }
      end
    end

  end
end

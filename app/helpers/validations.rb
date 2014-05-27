# gem used to validate email address:
require 'validates_email_format_of'
# We use resolv to validate IPv4 & Ipv6 addresses. It is better
# than ipaddr (ipaddr uses socket lib to validate can trigger dns lookups)
require 'resolv'

# A module for methods used to validate data, such as valid
# transaction parameters, social security numbers, emails and the like.
module PRGMQ
  module CAP
    module Validations

        ########################################
        ##            Constants:               #
        ########################################

        SSN_LENGTH          = 9    # In 2014 SSN length was 9 digits.
        # source: http://www.rfc-editor.org/errata_search.php?rfc=3696&eid=1690
        MAX_EMAIL_LENGTH    = 254  # IETF maximum length RFC3696/Errata ID: 1690
        DTOP_ID_MAX_LENGTH  = 20   # Arbitrarily selected length. Review this!
        MAX_NAME_LENGTH     = 255  # Max length for individual components of
                                   # a full name (name, middle, last names)
        MAX_RESIDENCY_LENGTH= 255  # max residency length
        MINIMUM_AGE         = 18   # Edad minima para solicitar un certificado

        DATE_FORMAT         = '%d/%m/%Y'  # day/month/year

        ########################################
        ##            Validations:             #
        ########################################

        # validates parameters in a hash, returning proper errors
        def validate_transaction_params(params)
          # strip the parameters of any extra spaces, save everything as string:
          params.each do |key, value|
            params[key] = value.to_s.strip
          end

          # Return proper errors if parameter is missing:
          raise MissingEmail           if params("email").length == 0
          raise MissingSSN             if params["ssn"].length == 0
          raise MissingLicenseNumber   if params["license_number"].length == 0
          raise MissingFirstName       if params["first_name"].length == 0
          raise MissingLastName        if params["last_name"].length == 0
          raise MissingResidency       if params["residency"].length == 0
          raise MissingBirthDate       if params["birth_date"].length == 0
          raise MissingClientIP        if params["IP"].length == 0
          raise MissingReason          if params["reason"].length == 0

          # Validate the Email
          raise InvalidEmail           if validate_email(params["email"])

          # Validate the SSN
          # we eliminate any potential dashes in ssn
          params["ssn"] = params["ssn"].gsub("-", "").strip
          raise InvalidSSN             if !validate_ssn(param["ssn"])

          # Validate the DTOP id:
          raise InvalidLicenseNumber   if !validate_id(params["license_number"])

          raise InvalidFirstName       if !validate_name(params["first_name"])
          raise InvalidMiddleName      if !validate_name(params["middle_name"])
          raise InvalidLastName        if !validate_name(params["last_name"])
          raise InvalidMotherLastName  if !validate_name(params["mother_last_name"])

          raise InvalidResidency       if !validate_residency(params["residency"])

          # This validates birthdate
          raise InvalidBirthDate       if !validate_birthdate(params["birth_date"])
          # This checks minimum age
          raise InvalidBirthDate       if !validate_birthdate(params["birth_date"], true)
          raise InvalidClientIPv4      if !validate_ip(params["IP"])
          return params
        end

        # Validate Social Security Number
        def validate_ssn(value)
          value = value.to_s
          # validates if its an integer
          true if(validate_str_is_integer(value) and value.length == SSN_LENGTH)
          false
        end

        # Check the email address
        def validate_email(value)
          # Optionally we could force DNS lookups using ValidatesEmailFormatOf
          # by sending validate_email_format special options after the value
          # such as mx=true (see gem's github), however, this requires dns
          # availability 24/7, and we'd like this system to work a little more
          # independently, so for now simply check against the RFC 2822,
          # RFC 3696 and the filters in the gem.
          true if (ValidatesEmailFormatOf::validate_email_format(value).nil? and
                   value.length > MAX_EMAIL_LENGTH )
          false
        end

        # validates if a string is an integer
        def validate_str_is_integer(value)
          !!(value =~ /\A[-+]?[0-9]+\z/)
        end

        # Validates a DTOP id
        def validate_id(value)
          false if(!validate_str_is_integer(value) or
                    value.length >= DTOP_ID_MAX_LENGTH )
          true
        end

        # used to validate names/middle names/last names/mother last name
        def validate_name(value)
          false if(value.length >= MAX_NAME_LENGTH)
          true
        end

        def validate_residency(value)
          false if(value.length >= MAX_RESIDENCY_LENGTH)
          true
        end

        def validate_birthdate(value, check_age=false)
          begin
            # check if valid date. if invalid, raise exception ArgumentError
            date = Date.strptime(value, DATE_FORMAT)
            # if it was required for us to validate minimum age
            if(check_age == true)
              if(age(date) >= MINIMUM_AGE)
                true # date was valid and the person is at least of minimum age
              end
              false # person isn't of minimum age
            end
            true # the date is valid
          rescue Exception => e
            # ArgumentError, the user entered an invalid date.
            false
          end
        end

        # Gets the age of a person based on their date of birth (dob)
        def age(dob)
          now = Date.today
          now.year - dob.year - ((now.month > dob.month ||
          (now.month == dob.month && now.day >= dob.day)) ? 0 : 1)
        end

        ###################################
        #  Validate IPv4 and IPv5         #
        ###################################
        def validate_ip(value)
          case value
          when Resolv::IPv4::Regex
            return true
          when Resolv::IPv6::Regex
            return true
          else
            return false
          end
        end
    end
  end
end

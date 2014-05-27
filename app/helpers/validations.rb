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
        def validate_transaction_parameters(params)
          # strip the parameters of any extra spaces, save everything as string:
          params.each do |key, value|
            params[key] = value.to_s.strip
          end

          # Return proper errors if parameter is missing:
          raise MissingEmail           if params["email"].length == 0
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
          raise InvalidSSN             if !validate_ssn(params["ssn"])

          # Validate the DTOP id:
          raise InvalidLicenseNumber   if !validate_id(params["license_number"])

          raise InvalidFirstName       if !validate_name(params["first_name"])
          raise InvalidMiddleName      if !params["middle_name"].nil? and
                                          !validate_name(params["middle_name"])
          raise InvalidLastName        if !validate_name(params["last_name"])
          raise InvalidMotherLastName  if !params["mother_last_name"].nil? and
                                          !validate_name(params["mother_last_name"])

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
          if(validate_str_is_integer(value) and value.length == SSN_LENGTH)
            true
          else
            false
          end
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
        #  Validate IPv4 and IPv6         #
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

# Ripped from https://github.com/alexdunae/validates_email_format_of
# and modified so it doesn't have any dependency on ActiveRecord.
# encoding: utf-8
module ValidatesEmailFormatOf

  VERSION = '1.5.3'

  LocalPartSpecialChars = /[\!\#\$\%\&\'\*\-\/\=\?\+\-\^\_\`\{\|\}\~]/

  def self.validate_email_domain(email)
    domain = email.match(/\@(.+)/)[1]
    Resolv::DNS.open do |dns|
      @mx = dns.getresources(domain, Resolv::DNS::Resource::IN::MX) + dns.getresources(domain, Resolv::DNS::Resource::IN::A)
    end
    @mx.size > 0 ? true : false
  end

  # Validates whether the specified value is a valid email address.  Returns nil if the value is valid, otherwise returns an array
  # containing one or more validation error messages.
  #
  # Configuration options:
  # * <tt>message</tt> - A custom error message (default is: "does not appear to be valid")
  # * <tt>check_mx</tt> - Check for MX records (default is false)
  # * <tt>mx_message</tt> - A custom error message when an MX record validation fails (default is: "is not routable.")
  # * <tt>with</tt> The regex to use for validating the format of the email address (deprecated)
  # * <tt>local_length</tt> Maximum number of characters allowed in the local part (default is 64)
  # * <tt>domain_length</tt> Maximum number of characters allowed in the domain part (default is 255)
  def self.validate_email_format(email, options={})
      default_options = { :message => 'does not appear to be valid',
                          :check_mx => false,
                          :mx_message => 'is not routable',
                          :domain_length => 255,
                          :local_length => 64
                          }
      opts = options.merge(default_options) {|key, old, new| old}  # merge the default options into the specified options, retaining all specified options

      email = email.strip if email

      begin
        domain, local = email.reverse.split('@', 2)
      rescue
        return [ opts[:message] ]
      end

      # need local and domain parts
      return [ opts[:message] ] unless local and not local.empty? and domain and not domain.empty?

      # check lengths
      return [ opts[:message] ] unless domain.length <= opts[:domain_length] and local.length <= opts[:local_length]

      local.reverse!
      domain.reverse!

      if opts.has_key?(:with) # holdover from versions <= 1.4.7
        return [ opts[:message] ] unless email =~ opts[:with]
      else
        return [ opts[:message] ] unless self.validate_local_part_syntax(local) and self.validate_domain_part_syntax(domain)
      end

      if opts[:check_mx] and !self.validate_email_domain(email)
        return [ opts[:mx_message] ]
      end

      return nil    # represents no validation errors
  end


  def self.validate_local_part_syntax(local)
    in_quoted_pair = false
    in_quoted_string = false

    (0..local.length-1).each do |i|
      ord = local[i].ord

      # accept anything if it's got a backslash before it
      if in_quoted_pair
        in_quoted_pair = false
        next
      end

      # backslash signifies the start of a quoted pair
      if ord == 92 and i < local.length - 1
        return false if not in_quoted_string # must be in quoted string per http://www.rfc-editor.org/errata_search.php?rfc=3696
        in_quoted_pair = true
        next
      end

      # double quote delimits quoted strings
      if ord == 34
        in_quoted_string = !in_quoted_string
        next
      end

      next if local[i,1] =~ /[a-z0-9]/i
      next if local[i,1] =~ LocalPartSpecialChars

      # period must be followed by something
      if ord == 46
        return false if i == 0 or i == local.length - 1 # can't be first or last char
        next unless local[i+1].ord == 46 # can't be followed by a period
      end

      return false
    end

    return false if in_quoted_string # unbalanced quotes

    return true
  end

  def self.validate_domain_part_syntax(domain)
    parts = domain.downcase.split('.', -1)

    return false if parts.length <= 1 # Only one domain part

    # Empty parts (double period) or invalid chars
    return false if parts.any? {
      |part|
        part.nil? or
        part.empty? or
        not part =~ /\A[[:alnum:]\-]+\Z/ or
        part[0,1] == '-' or part[-1,1] == '-' # hyphen at beginning or end of part
    }

    # ipv4
    return true if parts.length == 4 and parts.all? { |part| part =~ /\A[0-9]+\Z/ and part.to_i.between?(0, 255) }

    return false if parts[-1].length < 2 or not parts[-1] =~ /[a-z\-]/ # TLD is too short or does not contain a char or hyphen

    return true
  end

  module Validations
    # Validates whether the value of the specified attribute is a valid email address
    #
    #   class User < ActiveRecord::Base
    #     validates_email_format_of :email, :on => :create
    #   end
    #
    # Configuration options:
    # * <tt>message</tt> - A custom error message (default is: "does not appear to be valid")
    # * <tt>on</tt> - Specifies when this validation is active (default is :save, other options :create, :update)
    # * <tt>allow_nil</tt> - Allow nil values (default is false)
    # * <tt>allow_blank</tt> - Allow blank values (default is false)
    # * <tt>check_mx</tt> - Check for MX records (default is false)
    # * <tt>mx_message</tt> - A custom error message when an MX record validation fails (default is: "is not routable.")
    # * <tt>if</tt> - Specifies a method, proc or string to call to determine if the validation should
    #   occur (e.g. :if => :allow_validation, or :if => Proc.new { |user| user.signup_step > 2 }).  The
    #   method, proc or string should return or evaluate to a true or false value.
    # * <tt>unless</tt> - See <tt>:if</tt>
    def validates_email_format_of(*attr_names)
      options = { :on => :save,
        :allow_nil => false,
        :allow_blank => false }
      options.update(attr_names.pop) if attr_names.last.is_a?(Hash)

      validates_each(attr_names, options) do |record, attr_name, value|
        errors = ValidatesEmailFormatOf::validate_email_format(value.to_s, options)
        errors.each do |error|
          record.errors.add(attr_name, error)
        end unless errors.nil?
      end
    end
  end
end

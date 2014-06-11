module PRGMQ
  module CAP
    class TransactionMachine < PRGMQ::CAP::Base
      include AASM           # use the act as state machine gem

      PRGOV_FROM_ADDRESS = "noreply@pr.gov"

      ####################################
      #          State Machine           #
      ####################################

      # At every retrying step we have to check if we've
      # moved beyond the current state. If so, this
      # step doesn't have to be retried. IE: if we're
      # trying to send a sijc email receipt, but it failed
      # because our smtp was down, we keep retrying
      # but if we get a callback from SIJC with the
      # certificate ready, we skip this retrying and
      # simply send to certificate to the user and
      # the retrying job will see this, and end its
      # retries.
      aasm do
        ##################################################
        #                   Initial State                #
        ##################################################

        state :awaiting_initial_request_from_prgov, :initial => true

        ##################################################
        #           Email the initial receipt            #
        ##################################################
        state :recieved_initial_request_from_prgov
        state :ready_to_send_prgov_receipt_to_user
        state :sending_prgov_receipt_to_user
        state :retry_sending_prgov_receipt_to_user
        # If success:
        state :done_sending_prgov_receipt_to_user
        # If exponential retry failure:
        state :failed_sending_prgov_receipt_to_user

        ##################################################
        #     Validate Identity and Rapsheet with SIJC   #
        ##################################################
        state :ready_to_validate_rapsheet_with_sijc
        state :validating_rapsheet_with_sijc
        state :retry_validating_rapsheet_with_sijc
        # If success:
        state :done_validating_rapsheet_with_sijc
        # If exponential retry failure:
        state :failed_validating_rapsheet_with_sijc

        ##################################################
        #         Email the secondary receipt            #
        ##################################################
        # If DTOP ID was valid and rapsheet negative
        # we notify that SIJC is generating the certificate,
        # and PR.gov awaits the http callback from SIJC.
            state :ready_to_send_sijc_receipt_dtop_ok_raspheet_ok_to_user
            state :sending_sijc_receipt_dtop_ok_raspheet_ok_to_user
            state :retry_sending_sijc_receipt_dtop_ok_raspheet_ok_to_user
            # If success:
            state :done_sending_sijc_receipt_dtop_ok_raspheet_ok_to_user
            # If exponential retry failure:
            state :failed_sending_sijc_receipt_dtop_ok_raspheet_ok_to_user
        # If DTOP ID was invalid and rapsheet negative
        # we notify that we were unable to validate the identity, but
        # that the user appears to have a positive rapsheet.
        # We give them instructions in dealing with the Positive rapsheet.
        # We give them instructions in dealing with DTOP id.
            state :ready_to_send_sijc_receipt_dtop_fail_raspheet_ok_to_user
            state :sending_sijc_receipt_dtop_fail_raspheet_ok_to_user
            state :retry_sending_sijc_receipt_dtop_fail_raspheet_ok_to_user
            # If success:
            state :done_sending_sijc_receipt_dtop_fail_raspheet_ok_to_user
            # If exponential retry failure:
            state :failed_sending_sijc_receipt_dtop_fail_raspheet_ok_to_user
        # If DTOP ID was valid and rapsheet positive
        # we notify that we able to validate the identity, but
        # that the user appears to have a positive rapsheet.
        # We give them instructions in dealing with the Positive rapsheet.
            state :ready_to_send_sijc_receipt_dtop_ok_raspheet_fail_to_user
            state :sending_sijc_receipt_dtop_ok_raspheet_fail_to_user
            state :retry_sending_sijc_receipt_dtop_ok_raspheet_fail_to_user
            # If success:
            state :done_sending_sijc_receipt_dtop_ok_raspheet_fail_to_user
            # If exponential retry failure:
            state :failed_sending_sijc_receipt_dtop_ok_raspheet_fail_to_user

        # If RCI determines this is a result and we need
        # manual PRPD evaluation:
            # state :ready_to_send_sijc_receipt_rci_fuzzy_to_user
            state :sending_sijc_receipt_rci_fuzzy_to_user
            state :retry_sending_sijc_receipt_rci_fuzzy_to_user
            # If success:
            state :done_sending_sijc_receipt_rci_fuzzy_to_user
            # If exponential retry failure:
            state :failed_sending_sijc_receipt_rci_fuzzy_to_user

        ##################################################
        #   Manual Validation by Analysts at PRPD (ANPE) #
        ##################################################
        state :ready_to_submit_to_prpd_for_manual_review
        state :submitting_to_prpd_for_manual_review
        state :retry_submission_to_prpd_for_manual_review
        # If success:
        state :done_submitting_to_prpd_for_manual_review
        # If exponential retry failure:
        state :failed_submitting_to_prpd_for_manual_review

        ##################################################
        #        Response Recieved from PRPD             #
        ##################################################

        # If PRPD said we can proceed to send negative
        # certificate:
            state :ready_to_send_prpd_certificate_raspheet_ok_to_user
            state :sending_prpd_certificate_raspheet_ok_to_user
            state :retry_prpd_certificate_raspheet_ok_to_user
            # If success:
            state :done_sending_prpd_certificate_raspheet_ok_to_user
            # If exponential retry failure:
            state :failed_sending_prpd_certificate_raspheet_ok_to_user

        # If PRPD said we can't proceed to send negative
        # certificate:
            state :ready_to_send_prpd_receipt_raspheet_fail_to_user
            state :sending_prpd_receipt_raspheet_fail_to_user
            state :retry_prpd_receipt_raspheet_fail_to_user
            # If success:
            state :done_sending_prpd_receipt_raspheet_fail_to_user
            # If exponential retry failure:
            state :failed_sending_prpd_receipt_raspheet_fail_to_user


        ##################################################
        #             Events that fire States            #
        ##################################################

        ##################################################
        #            RAPSHEET REQUEST STATES             #
        ##################################################

        # First event, called by the API when request is received.
        # If a transaction is ever found stored but not enqueued,
        # it is possible the transcation was saved, but never made it
        # to the queue, due to an unexpected system shutdown, for example.
        event :received_prgov_request do
          transitions :from => :awaiting_initial_request_from_prgov,
                        :to => :recieved_initial_request_from_prgov
        end

        # We order the Transaction to send the receipt, by enqueing it
        # immediately after this event.
        event :send_prgov_receipt do
          transitions :from => :recieved_initial_request_from_prgov,
                        :to => :ready_to_send_prgov_receipt_to_user
        end


        ##################################################
        #               SIJC RAPSHEET REQUEST            #
        ##################################################


        # This event initiates a rapsheet request validation
        event :request_rapsheet
          # We can transition into this validation state from ready state
          # We can also enter this after a failed attempt,
          # such as a client that is awaiting a retry or failed.
          transitions :from => [:ready_to_validate_rapsheet_with_sijc,
                                :retry_validating_rapsheet_with_sijc,
                                :failed_validating_rapsheet_with_sijc],
                      :to   => :validating_rapsheet_with_sijc
        end

        # This event grabs a failed transaction, and attempts a
        # retry.
        event :request_rapsheet_retry
          transitions :from => :failed_validating_rapsheet_with_sijc,
                      :to   => :retry_validating_rapsheet_with_sijc
        end

        # When we successfully complete a transaction, we change to the
        # done state.
        event :request_rapsheet_done
          transitions :from => :validating_rapsheet_with_sijc,
                      :to   => :done_validating_rapsheet_with_sijc
        end

        # When a transaction failure event is fired, we enter this state.
        event :request_rapsheet_failed
          transitions :from => :validating_rapsheet_with_sijc,
                      :to   => :failed_validating_rapsheet_with_sijc
        end

        ##################################################
        #   Notify User SIJC requires PRPD validation    #
        ##################################################

        event :ready_to_send_fuzzy_receipt do
          :failed_validating_rapsheet_with_sijc
        end

        event :send_fuzzy_receipt do
          transitions :from => [:done_validating_rapsheet_with_sijc,
                                :retry_sending_sijc_receipt_rci_fuzzy_to_user],
                      :to   => :sending_sijc_receipt_dtop_ok_raspheet_ok_to_user
        end

        event :sending_fuzzy_receipt do
          transitions :from => :
        end



state :ready_to_send_sijc_receipt_rci_fuzzy_to_user
state :sending_sijc_receipt_rci_fuzzy_to_user
state :retry_sending_sijc_receipt_rci_fuzzy_to_user
# If success:
state :done_sending_sijc_receipt_rci_fuzzy_to_user
# If exponential retry failure:
state :failed_sending_sijc_receipt_rci_fuzzy_to_user

        event :ready_to_send_sijc_receipt_rci_fuzzy_to_user
          transitions :from => :done_validating_rapsheet_with_sijc
                      :to   => :ready_to_send_sijc_receipt_rci_fuzzy_to_user
        end

        ##################################################
        #                 PRPD ANPE STATES               #
        ##################################################

        event :request_prpd_review
          transitions :from => [:done_validating_rapsheet_with_sijc,
                                :retry_submission_to_prpd_for_manual_review],
                      :to   => :ready_to_submit_to_prpd_for_manual_review
        end

        event :request_prpd_retry
          transitions :from => :failed_submitting_to_prpd_for_manual_review,
                      :to   => :retry_submission_to_prpd_for_manual_review
        end

        event :request_prpd_done
          transitions :from => :validating
        end

state :ready_to_submit_to_prpd_for_manual_review
state :submitting_to_prpd_for_manual_review
state :retry_submission_to_prpd_for_manual_review
# If success:
state :done_submitting_to_prpd_for_manual_review
# If exponential retry failure:
state :failed_submitting_to_prpd_for_manual_review

        state :ready_to_submit_to_prpd_for_manual_review
        state :submitting_to_prpd_for_manual_review
        state :retry_submission_to_prpd_for_manual_review
        # If success:
        state :done_submitting_to_prpd_for_manual_review
        # If exponential retry failure:
        state :failed_submitting_to_prpd_for_manual_review



        end

      end # end of aasm

      def load_state(state)
          self.aasm.current_state = state
      end

      def current_state
        self.aasm.current_state
      end


      ############################################################
      #          Methods that change the State Machine           #
      ############################################################

      def received_prgov_request
        # Here we log that we received the request. This method
        # is launched from the event of the state machine.
      end

      def send_prgov_receipt
        ## Todo: later we should load this message from a disk configuration file
        message = "Hemos recibido una solicitud de Certificado de Antecedentes Penales "+
                  "a ser enviado a su correo electrónico, y estamos procesando la misma. "+
                  "Nuestro proceso conlleva validar la identidad del ciudadano para el "+
                  "cual se ha solicitado el certificado, al igual que una verificación "+
                  "exhaustiva de los record del histórico criminal. Próximamente "+
                  "recibirá un correo con el resultado de la validación. \n\n"+
                  "Gracias por utilizar los servicios de PR.gov."
        payload = {
                            "email" => self.email,
                            "from"  => PRGOV_FROM_ADDRESS,
                            "message" => message

                  }
        # Resque.enqueue(MailReceipt, self.id, payload)
      end

      # This is the attempt to validate the citizen's good standing
      # here we enqueue the worker of the Government Message Queue
      def request_rapsheet
          Resque.enqueue(RequestRapsheet, self.id, self.to_json)
      end

      # def request_rapsheet
      # end

      def send_rapshsheet_receipt
        ## Todo: later we should load this message from a disk configuration file
        message = "La información "
        payload = {
                            "email" => self.email,
                            "from"  => PRGOV_FROM_ADDRESS,
                            "message" => message

                  }
        # Resque.enqueue(MailReceipt, self.id, payload)
      end

      # This method initiates a retry for rapsheet validation
      def request_rapsheet_retry
        # We just need to log that an attempt was requested.
        puts "Log here that Rapsheet validation retry was requested for "+
             "#{self.id}"
        # and start the retry with the proper event changes:
        self.request_rapsheet
      end

      def request_rapsheet_failed
        # We need to log that a rapsheet request has failed.
        # This could mean many things, from SIJC being down, to RCI
        # having problems, to Red Gubernamental having infrastructure
        # problems, to our datacenter and server experiencing issues.
      end

      def send_to_prpd
        # here we enqueue a worker to talk with the PRPD's ANPE API
        # Resque.enqueue(AnpeWorker, self.id, self.to_json)
      end

      # used to notify the user the response
      # by the analyst. Either it was approved or not
      def send_prpd_receipt(emit_certificate)
        # if true, the analyst said yes and we'll ask sijc to generate cert
        # if faslse, the analyst said we can't, and we'll email the user
        # the information
      end

      # used after SIJC has confirmed via callback that the
      # certificate is ready
      def send_negative_certificate

      end

      # def enqueue_send_prgov_receipt
      #     # Resque.enqueue(MailReceipt, self.id, self.email)
      # end
      #
      # def enqueue_send_negative_certificate
      #     # Resque.enqueue(MailCertificate, self.id, self.email)
      # end
      #
      # def enqueue_send_negative_certificate
      #     # Resque.enqueue(MailCertificate, self.id, self.email)
      # end

    end
  end
end
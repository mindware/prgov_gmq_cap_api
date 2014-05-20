# RESTful API for interacting with the Government Message Queue (GMQ) of PR.Gov
# Some code and ideas recycled with permission from:
# github.com/mindware/Automata
# CAP API 2014 (c) Office of the CIO of Puerto Rico
# Developed by: Andrés Colón Pérez for Office of the CIO
# For: Estado Libre Asociado de Puerto Rico
# Load our Libraries, Settings and Helper Methods:
require 'json'
require './app/helpers/library'
require './app/helpers/config'
require './app/helpers/authentication'
require './app/helpers/errors'
# Models contain information stored in an Object:
require './app/models/transaction'
require './app/models/user'
# Grape-Entitty are API representations of a Model:
require './app/entities/transaction'

module PRGMQ
	module CAP
		class API < Grape::API

			version 'v1'
			format :json

			# Our middleware to trap exception and return json gracefully.
			use ApiErrorHandler

			# Our helpers
			helpers do
				include PRGMQ::CAP::Library	# General Helper Methods
			end

			http_basic do |username, password|
			  # verify user's password here
			  Authentication.valid?(username, password)
			end

			# From here on the user is authenticated. Any checks should be for
			# specific access.

			## Resource cap:
			## All the request below require a /v1/ before the resource, ie:
			## GET /v1/cap/...
			resources :cap do
				desc "Returns current version and status information. This is "+
						 "mainly used to test credentials and in the future could be used "+
						 "to see health information."
				# Get cap/
				get '/' do
					# specify a list of user groups than can access this resource:
					allowed_groups = ["all"]
					# validate if this user belongs to the alllowed groups,
					# if it does, get the User Object, else: we'll safely error out.
					user = allowed?(env["REMOTE_USER"], allowed_groups)
					# logger.info "#{user} requested #{route.route_params[params]}"
					{ :api	=> "CAP", :versions => "#{API::versions}" }
				end # end of get '/'

				# This resource is here for testing things. It's our own special lab.
				# Get cap/test
				get '/test' do
					# specify a list of user groups than can access this resource:
					allowed_groups = ["admin"]
					# validate if this user belongs to the alllowed groups,
					# if it does, get the User Object, else: we'll safely error out.
					user = allowed?(env["REMOTE_USER"], allowed_groups)
					{ :object => Config.data }
				end # end of get '/test'

				## Resource cap/transaction:
				group :transaction do

						## Resource cap/transaction/status:
						group :status do
							# GET cap/transaction/status/:status:
							desc "Returns an estimated number of existing transactions in "+
									 "the CAP Transaction system that match a specific status."
							params do
								requires :status, type: String, desc: "A valid status id."
							end
							get "/" do
										{
									     :transactions =>
											 {
					                :status =>
													{
			                      	:status => "20"
						              }
									     }
										}
							end
						end

						## Resource cap/transaction/:id:
						desc "Returns all available information on a specific "+
								 "transaction id."
						params do
							requires :id, type: String, desc: "A valid transaction id."
						end
						namespace ":id" do
							# Resource cap/transaction/:id/status:
							group :status do
								# GET cap/transaction/:id/status/
								desc "Returns relevant status information on a specific "+
										 "transaction id."
								get "/" do
										{
										    "transaction" => {
										        "id" => "0-123-456",
										        "current_error_count" => 0,
										        "total_error_count" => 1,
										        "action" => {
										             "id" => 10,
										             "description" => "sending certificate via email"
										         },
										        "status" => "processing",
										        "location" => "prgmq_email_certificate_queue",
										    }
										}
								end
							end

							# GET /v1/cap/transaction/:id/
							desc "Returns all available information on a specific "+
									 "transaction id."
							params do
								optional :id, type: String, desc: "A valid transaction id."
							end
							get do
									allowed_groups = ["admin"]
									user = allowed?(env["REMOTE_USER"], allowed_groups)
									@transaction = Transaction.new
									present @transaction, with: PRGMQ::CAP::Entities::Transaction
							end

							# DELETE /v1/cap/transaction/:id
							desc "Deletes a specific transaction id so it cannot be processed. "+
									"This will likely move the transaction to an alternative "+
									"repository in the future, uso as to archive it. This is "+
									"mainly to be used by workers, or for administrative purposes"+
									" such as when duplicates are detected."
							params do
								requires :id, type: String, desc: "A valid transaction id."
							end
							delete do
								{
										"0-123-456" => "deleted"
								}
							end # end of DELETE
						end # end of namespace: Resource cap/transaction/:id:

						# GET /v1/cap/transaction/
						desc "Returns an estimated number of existing transactions in "+
								"the CAP Transaction system."
						get '/' do
							{
								"transactions" =>
								{
										"pending" => "20",
										"completed" => "100",
										"failed" => "1",
										"retry" => "2",
										"processing" => "5",
								}
							}
						end

						# POST /v1/cap/transaction/
						desc "Request to generate a new transaction, which involves "+
								 "attempting to enqueue the request with a unique transaction "+
								 "id and returning said id."
						params do
							requires :payload, type: String, desc: "A valid transaction payload."
						end
						post '/' do
						{
						    "transaction" =>
								{
						        "id" => "0-123-456",
						        "action" => {
						            "id" => 1,
						            "description" => "validating identity and rapsheet with DTOP & SIJC"
						         },
						        "status" => "pending",
						        "location" => "prgmq_validate_rapsheet_with_sijc_queue",
						    }
						}
						end

						# PUT /v1/cap/transaction/
						desc "Requests that the server update information for a given id. "+
								 "This is used to update the current state of a transaction, "+
								 "such as its current location in the message queue or an "+
								 "external system. It may also be used to fix the email for "+
								 "a certain transaction. The transaction id can not be changed."
						params do
							# Remove the following and add actual parameters later.
							requires :payload, type: String, desc: "A valid transaction payload."
						end
						post '/' do
						{
							    "transaction"=> {
							        "id" => "0-123-456",
							        "current_error_count" => 0,
							        "total_error_count" => 1,
							        "action" => {
							            "id" => 10,
							            "description" => "sending certificate via email"
							         },
							        "email" => "levipr@gmail.com",
							        "history" => {
							           "created_at"  => "5/10/2014 2=>30=>00AM",
							           "updated_at" => "5/10/2014 2=>36=>53AM",
							           "updates" => {
							             "5/10/2014 2=>31=>00AM" => "Updating email per user request=> (params=> ‘email’ => ‘levipr@gmail.com’) ",
							           },
							           "failed" => {
							                 "5/10/2014 2=>36=>52AM" => {
							                        "sijc_rci_validate_dtop" => {
							                                     "http_code" =>  502,
							                                     "app_code" =>  8001,
							                         },
							                  },
							            },
											 },
							         "status" => "processing",
							         "location" => "prgmq_email_certificate_queue",
							    }
							}
						end
				end # end of group: Resource cap/transaction:
			end
		end
	end
end

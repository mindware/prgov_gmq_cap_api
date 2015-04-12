# RESTful API for interacting with the Government Message Queue (GMQ) of PR.Gov
# Some code and ideas recycled with permission from:
# github.com/mindware/Automata
# CAP API 2014 (c) Office of the CIO of Puerto Rico
# Developed by: Andrés Colón Pérez for Office of the CIO
# For: Estado Libre Asociado de Puerto Rico

# Load our external libraries
require 'json'	  												# gives us JSON parse and to_json
# Load our Settings and Helper Methods:
require 'app/helpers/store'								# our storage subsystem.
require 'app/helpers/library'							# useful helper methods
require 'app/helpers/config'							# configuration helper
require 'app/helpers/authentication'			# authentication class
require 'app/helpers/errors'							# defines and catches errors
require 'app/helpers/validations'					# validates user input
require 'app/helpers/transaction_id_factory' # to generate ids

# Load our Models. Models contain information stored in an Object:
require 'app/models/base'
require 'app/models/transaction'
require 'app/models/user'
require 'app/models/statistics'
require 'app/models/message'
require 'app/models/validator'

# Load our Entities. Grape-Entities are API representations of a Model:
require 'app/entities/transaction'
require 'app/entities/transaction_created'

module PRGMQ
	module CAP
		class API < Grape::API

			include LibraryHelper

			def initialize
				begin
					puts "#{"API".bold.yellow}: Loading CAP API."
					# We don't validate store here, because it's not necessarily
					# available at this point.
					Store.connected?
					status = Store.connected? if !Store.nil?
					debug "Storage is #{status ? "online".bold.yellow : "offline".bold.red}!"
					super
				rescue Exception => e
					puts "Error initializing CAP API (Grape), was: #{e.message}\nBacktrace: #{e.backtrace[0]}"
					exit
				end
			end

			version 'v1'
	    content_type :json, "application/json;charset=UTF-8"
			format :json

			# Our middleware to trap exception and return json gracefully.
			use ApiErrorHandler

			# Our helpers
			helpers do
				include PRGMQ::CAP::LibraryHelper	# General Helper Methods
			end

			http_basic do |username, password|
			  # verify user's password here
			  if(Authentication.valid?(username, password))
					debug("Authentication Successful "+
							  "for user: #{username.yellow}")
					true
				else
					debug("#{"Invalid credentials".bold.red}, provided user: "+
								"'#{username}'")
					raise InvalidCredentials
					# false
				end
			end


			before do
				# If we're in verbose mode, print everything to STDOUT
				# Print a set of dashes to make viewing output easier:
				debug "#{ ("-" * 80).bold.yellow }\n", false, false
				puts "Request Id: #{env["VISIT_ID"]}" unless env["VISIT_ID"].to_s.length == 0

				# If the system is set up for downtime/maintenance:
				if(Config.downtime)
					# get the path:
					path = route.route_path.gsub("/:version/cap", "")
					# Only admin resources are allowed during maintenance mode.
					# Throw an error if this isn't an admin path.
					if !path.start_with?("/admin/")
						# Let the users know this system is down for maintenance:
						raise ServiceUnavailable
					end
				else
						# We add visits when we're outside of maintenance mode, as the
						# storage could be offline during maintenance.

						# We need to track every request, so we can safely tag each debug()
						# line, so that logs can be tracked when there are multiple
						# concurrent requests

						# Exclude specific paths from adding visits
						# TODO: consider using start_with? here.
						path = route.route_path.gsub("(.:format)", "")
						begin
							if !path.start_with? "/:version/cap/admin/maintenance" and
							 	 !path.start_with? "/:version/cap/health" #and !Config.downtime
										# Add a visit, and save it as string.
										env["VISIT_ID"] = add_visit.to_s
							else
										# No id for empty visits
										env["VISIT_ID"] = "-"
							end
						rescue
							  # Storage could not be accessed. Instead of erroring out here
								# we'll let this pass so we can print request_info, and the
								# error will be caught by the API resource in question.
						end
				end
				debug "#{request_info}"
			end

			# After every request
			after do
				# print dashes signifying end of output
				debug "#{ ("-" * 80).bold.yellow }\n", false, false
			end

			# From here on the user is authenticated. Any checks should be for
			# specific access.

			## Resource cap:
			## All the request below require a /v1/ before the resource, ie:
			## GET /v1/cap/...
			resources :cap do
				desc 'Allows for sending email messages.'

				# Allows for sending email messages
				post '/mail' do
						user = allowed?(["prgov", "admin", "worker"])
						mail = Message.email(params)
						result ({ :status => "queued" })
				end

				desc "Returns current version and status information. This is "+
						 "mainly used to test credentials and in the future could be used "+
						 "to see health information."
				# Get cap/
				get '/' do
					# specify a list of user groups than can access this resource
					# validate if this user belongs to the alllowed groups,
					# if it does, get the User Object, else: we'll safely error out.
					user = allowed?(["all"])
					# logger.info "#{user} requested #{route.route_params[params]}"
					result ({ :api	=> "CAP", :versions => "#{API::versions}"})
				end # end of get '/'

				# Check the health for the system
				desc "Performs an API health check"
				get '/health' do
					# the only reason where we don't check for authentication
					# since if the storage server is down, we won't be able to
					# even get to the authentication in order to answer the health
					# check:
					result ({ :storage_online => Store.connected?, :maintenance_mode => Config.downtime })
				end

				## Resource cap/transaction:
				group :transaction do

						## Resource cap/transaction/status:
						group :status do
							# GET cap/transaction/status/:status:
							# TODO: add this support
							desc "Returns an estimated number of existing transactions in "+
									 "the CAP Transaction system that match a specific status."
							params do
								requires :status, type: String, desc: "A valid status id."
							end
							get "/" do
								user = allowed?(["all"])
								result ({
										     :transactions =>
												 {
						                :status =>
														{
				                      	:status => "20"
							              }
										     }
											})
							end
						end


						# group into ../transaction/validate/
						group :validate do
								# Validator:
								# GET /v1/cap/transaction/validate/request
								desc "Requests that a transaction id be verified to see if it "+
										 "remains valid. This action will incorporate async requests to "+
										 "an external system. As such, if all input is valid it will "+
										 "return a request_id, whose status can be checked via other "+
										 "validation resources."
								params do
									optional :tx_id, type: String, desc: "A valid transaction id."
									optional :ssn, type: String, desc: "A valid ssn."
									optional :passport, type: String, desc: "A valid passport."
									optional :IP, type: String, desc: "A valid IP of the end user."
								end
								get '/request' do
										user = allowed?(["admin", "worker", "prgov", "prgov_validation"])
										transaction = Validator.create(params)
										# check if we are able to save it
										if transaction.save
											# result (present transaction, with: CAP::Entities::Validator) #, type: :hi
											result transaction
										else
											# if the item is not found, raise an error that it could not be saved
											raise TransactionNotFound
										end
								end

								# GET /v1/cap/transaction/validate/response
								desc "Requests that a validation's response be verified to see it "+
										 "has completed by providing a validation's request_id."
								params do
									optional :id, type: String, desc: "A validation request id."
								end
								get '/reponse' do
										user = allowed?(["admin", "worker", "prgov", "prgov_validation"])
										transaction = Validator.find(params)
										result transaction
										# result (present transaction, with: CAP::Entities::Validator) #, type: :hi
								end

								desc "Lists all available endpoints for this resource"
								get '/' do
										user = allowed?(["all"])
										result({
											"resources" => ["/response", "/request"]
										})
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
								# TODO: code this action
								desc "Returns relevant status information on a specific "+
										 "transaction id."
								get "/" do
										# so long as we only return general status info, we can
										# leave this open to all systems. If we start providing
										# specific user information, then only admin and workers.
										user = allowed?(["all"])
										result ({
										    "transaction" => {
										        "id" => "0-123-456-test",
										        "current_error_count" => 0,
										        "total_error_count" => 1,
										        "action" => {
										             "id" => 10,
										             "description" => "sending certificate via email"
										         },
										        "status" => "processing",
										        "location" => "prgmq_email_certificate_queue",
										    }
										})
								end
							end

							# GET /v1/cap/transaction/:id/
							desc "Returns all available information on a specific "+
									 "transaction id."
							params do
								optional :id, type: String, desc: "A valid transaction id."
							end
							get do
									user = allowed?(["admin", "worker"])
									transaction = Transaction.find(params[:id])
									result (present transaction, with: CAP::Entities::Transaction) #, type: :hi
							end

							# # PUT /v1/cap/transaction/validate/response
							# desc "Updates a validation's response by its request_id."
							# params do
							# 	optional :request_id, type: String, desc: "A validation request id."
							# end
							# put do
							# 		user = allowed?(["admin", "worker"])
							# 		transaction = Transaction.validate_response(params[:response_id])
							# 		# result (present transaction, with: CAP::Entities::Transaction) #, type: :hi
							# end

							# DELETE /v1/cap/transaction/:id
							desc "Deletes a specific transaction id so it cannot be processed. "+
									"This will likely move the transaction to an alternative "+
									"repository in the future, in order to archive it. This is "+
									"mainly to be used by workers, or for administrative purposes"+
									" such as when duplicates are detected."
							params do
								requires :id, type: String, desc: "A valid transaction id."
							end
							delete do
								user = allowed?(["admin"])
								transaction = Transaction.find(params["id"])
								transaction.destroy
								result ({
										"#{params["id"]}" => "deleted"
								})
							end # end of DELETE
						end # end of namespace: Resource cap/transaction/:id:

						# GET /v1/cap/transaction/
						# TODO: code this!
						desc "Returns an estimated number of existing transactions in "+
								"the CAP Transaction system."
						get '/' do
							user = allowed?(["all"])
							result({
								"transactions" =>
								{
										:pending => total_pending,
										:completed => total_completed,
										:visits => total_visits,
										"failed" => total_failed,
										"retry" => false,
										"processing" => false,
								}
							})
						end

						# POST /v1/cap/transaction/
						# this creates a transaction
						desc "Request to generate a new transaction, which involves "+
								 "attempting to enqueue the request with a unique transaction "+
								 "id and returning said id."
						post '/' do
							user = allowed?(["prgov", "admin"])
							# We store the IP of the system that made the direct request.
							# even if they will forward the originating IP, we grab theirs
							# in case we need to find out what server has been submitting
							# specific requests.
							# return params.class

							params[:system_address] = env['REMOTE_ADDR']
							params[:created_by] 		= user.name
							# Try to create it - if this fails, our error middleware catches it
							transaction = Transaction.create(params)
							# check if we are able to save it
							if transaction.save
								# Temporarily commented out until we can track the entities + pools
								# bug that is causing present to completely fail.
								# result present(transaction, with: CAP::Entities::TransactionCreated)

								# this fails sporadically
								# present transaction

								# this works perfectly, but doesn't limit the data we show prgov
								result transaction
								# transaction
							else
								# if the item is not found, raise an error that it could not be saved
								raise TransactionNotFound
							end
						end

						# PUT /v1/cap/transaction/review_complete
						desc "Confirms that an analyst at PRPD has completed manual revision of "+
						"this transaction, and requests that their decision_code be stored"+
						" and processed accordingly."
						params do
							# Remove the following and add actual parameters later.
							requires :id, type: String, desc: "A valid transaction id."
						end
						put 'review_complete' do
							user = allowed?(["sijc", "admin"])
							# try to find. If not found, an error is raised and sent.
							transaction = Transaction.find(params["id"])
							# once found, we grab the base64 parameters and update the object
							transaction.review_complete(params)
							# we try to save the transaction
							transaction.save
							result present(transaction, with: Entities::Transaction)
						end # end of review_complete

						# PUT /v1/cap/transaction/certificate_ready
						desc "Confirms that the enclosed base64 "+
								 "certificate has been generated at SIJC's RCI for this "+
								 "transaction, and it is ready to be sent to a proper "+
								 "email address."
						put 'certificate_ready' do
							user = allowed?(["sijc", "admin"])
							# try to find. If not found, an error is raised and sent.
							transaction = Transaction.find(params["id"])
							# once found, we grab the base64 parameters and update the object
							transaction.certificate_ready(params)
							# we try to save the transaction
							transaction.save
							result(present transaction, with: Entities::Transaction)
							# Only allowed to be set when PRPD requests so through their
							# action.
						end

						#
						# # PUT /v1/cap/transaction/
						# desc "Requests that the server update information for a given id. "+
						# 		"This is used to update the current state of a transaction, "+
						# 		"such as its current location in the message queue or an "+
						# 		"external system. It may also be used to fix the email for "+
						# 		"a certain transaction. The transaction id can not be changed."
						# params do
						# 	# Remove the following and add actual parameters later.
						# 	requires :payload, type: String, desc: "A valid transaction payload."
						# end
						# put '/' do
						# 	user = allowed?(["admin", "worker"])
						# 	{
						# 				"transaction"=> {
						# 						"id" => "0-123-456",
						# 						"current_error_count" => 0,
						# 						"total_error_count" => 1,
						# 						"action" => {
						# 								"id" => 10,
						# 								"description" => "sending certificate via email"
						# 						},
						# 						"email" => "levipr@gmail.com",
						# 						"history" => {
						# 							"created_at"  => "5/10/2014 2=>30=>00AM",
						# 							"updated_at" => "5/10/2014 2=>36=>53AM",
						# 							"updates" => {
						# 								"5/10/2014 2=>31=>00AM" => "Updating email per user request=> (params=> ‘email’ => ‘levipr@gmail.com’) ",
						# 							},
						# 							"failed" => {
						# 										"5/10/2014 2=>36=>52AM" => {
						# 														"sijc_rci_validate_dtop" => {
						# 																				"http_code" =>  502,
						# 																				"app_code" =>  8001,
						# 														},
						# 											},
						# 								},
						# 						},
						# 						"status" => "processing",
						# 						"location" => "prgmq_email_certificate_queue",
						# 				}
						# 		}
						# end
						#

				end # end of group: Resource cap/transaction:

				group :admin do

					group :stats do
						# This resource is here for admins.
						get '/visits' do
							user = allowed?(["admin"])
							result({ :visits => total_visits })
						end # end of get '/test'

						get '/completed' do
							user = allowed?(["admin"])
							result({ :completed => total_completed })
						end

						get '/' do
							user = allowed?(["admin"])
							result({
								:pending => total_pending,
							  :completed => total_completed,
							  :visits => total_visits
							})
						end
					end

					# This resource is here for testing things. It's our own special lab.
					# Get cap/test
					group :test do

						get '/stress' do
							# only allowed if we're in development or testing. Disabled on production.
							if(Goliath.env.to_s == "development" or Goliath.env.to_s.include? == "test")
								# specify a list of user groups than can access this resource:
								user = allowed?(["admin"])
								# Let's do a stress test.
								Transaction.stress_test_save
							else
								raise ResourceNotFound
							end
						end # end of get 'test/stress'

						get '/' do
							# only allowed if we're in development or testing. Disabled on production.
							if(Goliath.env.to_s == "development" or Goliath.env.to_s.include? == "test")
								# specify a list of user groups than can access this resource:
								user = allowed?(["admin"])
								# Write your test here:
								"Your test here"
							else
								raise ResourceNotFound
							end
						end # end of test's root resource '/'
					end # end of /test/ group

					# This resource is here for testing things. It's our own special lab.
					# Get cap/maintenance
					desc "Actives or deactives the system maintenance mode."
					params do
						optional :activate, type: Boolean, desc: "A boolean value that "+
																		"determines if we're down for maintenance."
					end
					get '/maintenance' do
						user = allowed?(["admin"])
						return {"maintenance_status" => Config.downtime } if params[:activate].nil?
						# make sure we're only sent correct data, true or false.
						# default value is false:
						value = false
						if params[:activate].to_s == "true"
							 # if the user requested we go into maintenance mode, set it to
							 # true
							 value = true
						end
						Config.downtime = value
						result({ "maintenance_status" => Config.downtime})
					end # end of get '/maintenance'

					# This resource is here for admins.
					get '/users' do
						user = allowed?(["admin"])
						result({ :users => user_list })
					end # end of get '/test'

					# This resource is here for admins.
					get '/groups' do
						user = allowed?(["admin"])
						result({ :groups => security_group_list })
					end # end of get '/test'

					desc "Reloads the configuration files into memory."
					get '/reload' do
						user = allowed?(["admin"])
						Config.load_config
						result({ :config => "Reloaded"})
					end

					desc "Lists the last incoming transactions"
					get '/last' do
						user = allowed?(["admin"])
						txs = last_transactions
						res = []

						# TODO: BUG:
						# This should not ocurr on Syncrhony driver. We shouldn't receive
						# a fixnum when we're doing a parallel request to Redis. However,
						# for some reason we are.
						#
						# If an error ocurred in parallel requests and the data is not an Array
						if txs.class != Array
							raise AppError
						end
						debug "We're going to process a data of length #{txs}" if txs.class != Array
						txs.each do |id|
							begin
								x = Transaction.find id
								res << [ x.id, x.ip, x.created_at, x.reason]
							rescue PRGMQ::CAP::TransactionNotFound
								# Ignore items that have been deleted.
								debug "Deleting a missing transaction #{id}..."
								Transaction.remove_id_from_last_list(id)
								debug "Deleted."
							end
						end
						result(res)
					end

					# Prints available admin routes. Hard-coded
					# Let's later do some meta-programming and catch these.
					# TODO: make this work via API introspection, show admin routes.
					get '/' do
						user = allowed?(["admin"])
						result ({
							"available_routes" => ["last", "maintenance", "test", "users",
																	   "groups",
																		 {"stats" => ["visits","completed"] } ]
						})
					end
				end # end of the administrator group
			end

			# consider adding a self documenting route, that simply lists all
			# routes, their descriptions and their parameters. Similar to:
			# http://code.dblock.org/grape-describing-and-documenting-an-api

			# Trap all errors, return proper 404:
			# This must always be the bottom route, nothing must be below it,
			# this is a catch all to return proper 404 errors.
			route :any, '*path' do
			  raise ResourceNotFound
			end

		end # end of API class
	end # end of CAP module
end # end of GMQ module

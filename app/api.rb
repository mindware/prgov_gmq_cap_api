# RESTful API for interacting with the Government Message Queue (GMQ) of PR.Gov
# Some code and ideas recycled with permission from:
# github.com/mindware/Automata
# CAP API 2014 (c) Office of the CIO of Puerto Rico
# Developed by: Andrés Colón Pérez for Office of the CIO
# For: Estado Libre Asociado de Puerto Rico

# Load our external libraries
require 'redis/connection/synchrony'         # use the asynchronous driver
require 'redis'															# use redis
require 'json'															 # gives us JSON parse and to_json

# Load our Settings and Helper Methods:
require 'app/helpers/store'								# our storage subsystem.
require 'app/helpers/library'							# useful helper methods
require 'app/helpers/config'							 # configuration helper
require 'app/helpers/authentication'			 # authentication class
require 'app/helpers/errors'							 # defines and catches errors
require 'app/helpers/validations'					# validates user input
require 'app/helpers/transaction_id_factory' # to generate ids

# Load our Models. Models contain information stored in an Object:
require 'app/models/base'
require 'app/models/transaction'
require 'app/models/user'
require 'app/models/statistics'

# Load our Entities. Grape-Entities are API representations of a Model:
require 'app/entities/transaction'
require 'app/entities/transaction_created'

module PRGMQ
	module CAP
		class API < Grape::API

			def initialize
				begin
					puts "Loading CAP API."
					# Store.connected?
					status = Store.connected? if !Store.nil?
					# puts "Storage is #{status ? "online" : "offline"}"
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
			  Authentication.valid?(username, password)
			end


			before do
				# If we're in verbose mode, print everything to STDOUT
				# Print a set of dashes to make viewing output easier:
				debug "#{ "-" * 80 }\n", false
				debug "Info: #{request_info}"

				logger.info "Hello world"

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
				end
			end

			# After every request, keep count of all global visits
			after do
				# Exclude specific paths from adding visits
				if !route.route_path.include? "/:version/cap/health"
						add_visit
						debug "Visit ID: #{total_visits}"
				end
				debug "#{ "-" * 80 }\n", false # print dashes signifying end of output
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
					# specify a list of user groups than can access this resource
					# validate if this user belongs to the alllowed groups,
					# if it does, get the User Object, else: we'll safely error out.
					user = allowed?(["all"])
					# logger.info "#{user} requested #{route.route_params[params]}"
					{ :api	=> "CAP", :versions => "#{API::versions}"}
				end # end of get '/'

				# Check the health for the system
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
							desc "Returns an estimated number of existing transactions in "+
									 "the CAP Transaction system that match a specific status."
							params do
								requires :status, type: String, desc: "A valid status id."
							end
							get "/" do
								user = allowed?(["all"])
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
										# so long as we only return general status info, we can
										# leave this open to all systems. If we start providing
										# specific user information, then only admin and workers.
										user = allowed?(["all"])
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
									user = allowed?(["admin", "worker"])
									transaction = Transaction.find(params[:id])
									result present transaction, with: CAP::Entities::Transaction #, type: :hi
							end

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
								user = allowed?(["admin", "worker"])
								{
										"0-123-456" => "deleted"
								}
							end # end of DELETE
						end # end of namespace: Resource cap/transaction/:id:

						# GET /v1/cap/transaction/
						desc "Returns an estimated number of existing transactions in "+
								"the CAP Transaction system."
						get '/' do
							user = allowed?(["all"])
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
						# this creates a transaction
						desc "Request to generate a new transaction, which involves "+
								 "attempting to enqueue the request with a unique transaction "+
								 "id and returning said id."
						post '/' do
							user = allowed?(["webapp", "admin"])
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
								present transaction, with:Entities::TransactionCreated
							else
								# if the item is not found, raise an error that it could not be saved
								raise ItemNotFound
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
							present transaction, with:Entities::Transaction
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
							result(present transaction, with:Entities::Transaction)
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
							  :completed => total_completed,
							  :visits => total_visits
							})
						end
					end

					# This resource is here for testing things. It's our own special lab.
					# Get cap/test
					get '/test' do
						# only allowed if we're in development or testing. Disabled on production.
						if(Goliath.env.to_s == "development" or Goliath.env.to_s.include? == "test")
							# specify a list of user groups than can access this resource:
							user = allowed?(["admin"])
							result({ :test_data =>  redis.get("mkey")})
						else
							raise ResourceNotFound
						end
					end # end of get '/test'


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
						Config.downtime = params[:activate]
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
						txs.each do |x|
							x = Transaction.find x
							res << [ x.id, x.ip, x.created_at, x.reason]
						end
						result(res)
					end

					# Prints available admin routes. Hard-coded
					# Let's later do some meta-programming and catch these.
					get '/' do
						result ({
							"available_routes" => ["maintenance", "test", "users", "visits",
																		 "recent"]
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

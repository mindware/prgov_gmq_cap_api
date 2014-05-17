require 'bundler/setup'
Bundler.require	# Load our Gemfile
require 'spec_helper'

describe Twitter::API do
  include Rack::Test::Methods

  def app
    Twitter::API
  end

  describe Twitter::API do
    describe "GET /api/v1/statuses" do
      it "returns an empty array of statuses" do
        get "/api/v1/statuses"
        last_response.status.should == 200
        JSON.parse(last_response.body).should == []
      end
    end
    describe "GET /api/v1/statuses/:id" do
      it "returns a status by id" do
        status = Status.create!
        get "/api/v1/statuses/#{status.id}"
        last_response.body.should == status.to_json
      end
    end
  end
end

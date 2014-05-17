require 'spec_helper'
require File.join(File.dirname(__FILE__), '../', 'app')

describe CAP do
  def config_file
    File.expand_path(File.join(File.dirname(__FILE__), '..', 'config', 'server.rb'))
  end

  let(:api_options) { { :config => config_file } }

  it 'renders ' do
    with_api(Cap, api_options) do
      get_request(:path => '/v1/transaction') do |c|
        resp = JSON.parse(c.response)
        transaction = resp.map{|r|r['transaction']}
        transaction.to_s.should =~ /123/
      end
    end
  end
end

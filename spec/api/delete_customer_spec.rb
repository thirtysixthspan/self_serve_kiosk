require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../auth_helper'

describe "Deleting a customer" do
  
  include Rack::Test::Methods
  include AuthHelper

  def app
    Sinatra::Application
  end  
  
  before :all do
    auth_login
  end
  
  before :each do
    @customer = Customer.new()
    @customer.save
  end

  it "using the API requires a valid customer ID" do
    delete "/api/v1/customer/#{@customer.uuid}", {}, @headers
    last_response.status.should == 200
    params = JSON.parse(last_response.body) 
    params.should include 'deleted'
    params['deleted'].should == true
  end

  it "using the API fails without a valid customer ID" do
    delete '/api/v1/customer/0', {}, @headers
    last_response.status.should == 404
    params = JSON.parse(last_response.body) 
    params.should include 'deleted'
    params['deleted'].should == false
  end
  
end
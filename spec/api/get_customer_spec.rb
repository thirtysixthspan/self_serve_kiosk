require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../auth_helper'

describe "Getting customer" do
  
  include AuthHelper

  def app
    Sinatra::Application
  end  
  
  before :all do
    auth_login
  end
  
  before :each do
   @c = Customer.new()
   @c.email = "Test#{rand(100000)}@gmail.com"
   @c.save
  end

  it "using the API requires a valid customer ID" do
    get "/api/v1/customer/#{@c.uuid}", {}, @headers
    last_response.status.should == 200
    params = JSON.parse(last_response.body) 
    params.should include 'customer'
    params['customer'].should be_a_kind_of Hash
    params['customer']['id'].should == @c.uuid
    params['customer']['email'].should == @c.email
  end

  it "using the API fails without a valid customer ID" do
    get '/api/v1/customer/0', {}, @headers
    last_response.status.should == 404
  end
  
end
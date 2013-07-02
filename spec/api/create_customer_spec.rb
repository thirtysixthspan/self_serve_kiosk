require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../auth_helper'

describe "Creating a customer" do
  
  include AuthHelper

  def app
    Sinatra::Application
  end  
  
  before :all do
    auth_login
  end

  it "using the API requires an email" do
    post '/api/v1/customer', { email: "Test#{rand(100000)}@gmail.com" }, @headers
    last_response.status.should == 200  
    params = JSON.parse(last_response.body) 
    params.should include 'id'
  end
  
  it "using the API fails when creating an ID without parameter" do
    post '/api/v1/customer', {}, @headers
    last_response.status.should == 400  
  end

  it "using the API fails when creating an ID with an empty full name" do
    post '/api/v1/customer', {:customer_full_name=>""}, @headers
    last_response.status.should == 400  
  end

end


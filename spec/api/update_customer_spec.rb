require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../auth_helper'

describe "Update customer" do
  
  include AuthHelper

  def app
    Sinatra::Application
  end  
  
  before :all do
    auth_login
  end
  
  before :each do
    @customer = Customer.new().save
    @update = {
      'cc_name' => 'Parkhurst/Derrick'
    }
  end

  it "using the API for existing customers accepts a valid customer ID" do
    put "/api/v1/customer/#{@customer.uuid}", @update, @headers
    last_response.status.should == 200
    params = JSON.parse(last_response.body) 
    params.should include 'customer'
    params['customer'].should be_a_kind_of Hash
    params['customer']['id'].should == @customer.uuid
    params['customer']['first_name'].should == @update['first_name']
    params['customer']['last_name'].should == @update['last_name']
  end

  it "using the API creates the ID if it doesn't exist" do
    put "/api/v1/customer/#{@customer.uuid}", @update, @headers
    last_response.status.should == 200
    params = JSON.parse(last_response.body) 
    params.should include 'customer'
    params['customer'].should be_a_kind_of Hash
    params['customer']['id'].should == @customer.uuid
    params['customer']['first_name'].should == @update['first_name']
    params['customer']['last_name'].should == @update['last_name']
  end

  it "using the API fails without properties" do
    put "/api/v1/customer/#{@customer.uuid}", {}, @headers
    last_response.status.should == 400
  end
  
end

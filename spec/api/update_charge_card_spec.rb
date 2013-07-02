require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../auth_helper'
require 'stripe'

describe "Update charge card" do
  
  include Rack::Test::Methods
  include AuthHelper

  def app
    Sinatra::Application
  end  
  
  before :all do
    auth_login

    @customer = Customer.new()
    r = rand(1000000)
    @customer.email = "test-#{r}@gmail.com"
    @customer.save
  end

  it "with Stripe for the first time using the API" do
    stripe_token = Stripe::Token.create( :card => { :number => "4242424242424242", :exp_month => 1, :exp_year => 2013, :cvc => 314 } )
    @query = {
      :id => @customer.uuid,
      :charge_method => 'stripe',
      :stripe_token_id => stripe_token.id
    }
    post '/api/v1/customer/charge', @query, @headers
    pp last_response unless last_response.status == 200
    last_response.status.should == 200
    params = JSON.parse(last_response.body) 
    params.should include 'card_updated'
    params['card_updated'].should == true

    get "/api/v1/customer/#{@customer.uuid}", {}, @headers
    last_response.status.should == 200
    params = JSON.parse(last_response.body) 
    params.should include 'customer'
    customer = params['customer']    
    customer.should be_a_kind_of Hash
    customer.should include 'charge_method'
    customer['charge_method'].should == 'stripe'
    customer.should include 'stripe_customer_id'    
  end

  it "with Stripe for the first time using the API without a token" do
    @query_no_token = {
      :id => @customer.uuid,
      :charge_method => 'stripe',
      :number => "4242424242424242", 
      :exp_month => 1, 
      :exp_year => 2020, 
      :cvc => 314
    }    
    post '/api/v1/customer/charge', @query_no_token, @headers
    pp last_response unless last_response.status == 200  
    last_response.status.should == 200  
    params = JSON.parse(last_response.body) 
    params.should include 'card_updated'
    params['card_updated'].should == true
    
    get "/api/v1/customer/#{@customer.uuid}", {}, @headers
    last_response.status.should == 200
    params = JSON.parse(last_response.body) 
    params.should include 'customer'
    customer = params['customer']    
    customer.should be_a_kind_of Hash
    customer.should include 'charge_method'
    customer['charge_method'].should == 'stripe'
    customer.should include 'stripe_customer_id'    
  end

  it "with Stripe using the API fails when creating an ID without parameters" do
    post '/api/v1/customer/charge', {}, @headers
    last_response.status.should == 400  
  end

  it "with Stripe using the API fails without an existing customer" do
    post '/api/v1/customer/charge', {:id=>"0"}, @headers
    last_response.status.should == 400  
  end
  
  it "with Stripe using the API fails without a charge method" do
    post '/api/v1/customer/charge', {:id=>@customer.uuid}, @headers
    last_response.status.should == 400  
  end

end


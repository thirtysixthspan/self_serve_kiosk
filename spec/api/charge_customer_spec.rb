require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../auth_helper'

describe "Charge an existing customer" do
  
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

    success, token = @customer.obtain_stripe_token( 
      :number => "4242424242424242", :exp_month => 1, :exp_year => 2013, :cvc => 314
    )
    puts token unless success
    success.should == true

    success, stripe_customer_id = @customer.create_stripe_customer
    puts stripe_customer_id unless success
    success.should == true
  end
  
  before :each do  
    r = rand(1000000)
    @charge = {
      :id => @customer.uuid,
      :amount => 1000,
      :description => "This is automated testing charge #{r}"
    }
  end

  it "with Stripe using the API" do
    get '/api/v1/customer/charge', @charge, @headers
    pp last_response unless last_response.status == 200
    last_response.status.should == 200
    params = JSON.parse(last_response.body)
    params.should include 'charged'
    params['charged'].should == true
    params['charge_id'].should be_a_kind_of String
    File.exist?("#{CHARGE_PATH}/#{@customer.uuid}-#{params['charge_id']}.stripe_charge").should == true
  end
  
  it "with Stripe using the API fails without a valid customer ID" do
    @charge['id'] = 0
    get '/api/v1/customer/charge', @charge, @headers
    last_response.status.should == 404  
  end
  
  it "with Stripe using the API fails without an amount" do
    @charge.delete(:amount)
    get '/api/v1/customer/charge', @charge, @headers
    last_response.status.should == 400  
  end

  it "with Stripe using the API fails without an description" do
    @charge.delete(:description)
    get '/api/v1/customer/charge', @charge, @headers
    last_response.status.should == 400  
  end
  
end



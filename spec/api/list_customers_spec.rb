require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../auth_helper'

describe "Listing customers" do
  
  include AuthHelper

  def app
    Sinatra::Application
  end  
  
  before :all do
    auth_login

    @c = []
    3.times do |i|
      @c[i] = Customer.new()
      @c[i].set({:first_name => "Test #{i}", :last_name => 'Customer'}) 
      @c[i].save
    end
   
  end

  it "using the API should provide an array of customer ids" do
    get '/api/v1/customer/list', {}, @headers
    last_response.status.should == 200
    params = JSON.parse(last_response.body) 
    params.should include 'ids'
    params['ids'].should be_a_kind_of Array
    3.times { |i| params['ids'].should include @c[i].uuid }
  end
  
end
require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../auth_helper'  

describe "Credit Cards" do
  
  include Rack::Test::Methods
  include AuthHelper

  def app
    Sinatra::Application
  end  
  
  before :all do

    CreditCard.generate_keys({
      :originator => "John Doe",
      :passphrase => AES_PASSPHRASE,
      :public_key_file_name => "/tmp/public.yaml",
      :private_key_file_name => "/tmp/private.yaml" 
    })

    ENC_SECRET = { 
      :aes_passphrase => AES_PASSPHRASE,
      :rsa_key => CreditCard.load_public_key(:passphrase => AES_PASSPHRASE, :key_file_name => "/tmp/public.yaml")
    }
    DEC_SECRET = { 
      :aes_passphrase => AES_PASSPHRASE,
      :rsa_key => CreditCard.load_private_key(:passphrase => AES_PASSPHRASE, :key_file_name => "/tmp/private.yaml")
    }      
    @cc_data = { 
      :timestamp => Time.now.to_i.to_s, 
      :name => 'Parkhurst/ Derrick J',
      :number => '1023102310231023',
      :exp_month => '12',
      :exp_year => '2014'
    }
    cc = CreditCard.new( @cc_data, ENC_SECRET )
    @signed_query = CreditCard.add_signature({:data => cc.encrypted},AES_PASSPHRASE)
    @incorrectly_signed_query = CreditCard.add_signature({:data => cc.encrypted} ,'this is wrong')
  end

  describe "submitted by server" do

    it "fails without a card swipe request" do

      REDIS.del "last_card_token"

      post '/store/card', @signed_query
      pp last_response unless last_response.status == 400
      last_response.status.should == 400

      params = JSON.parse(last_response.body) 
      params.should include 'status_message'
      params['status_message'].should == 'no card swipe requested' 
    end

    it "requires properly signed data and an accepted card swipe request" do
      get '/store/request_card_swipe'
      params = JSON.parse(last_response.body) 
      params.should include 'card_token'

      post '/store/card', @signed_query
      pp last_response unless last_response.status == 200
      last_response.status.should == 200  
      params = JSON.parse(last_response.body) 
      params.should include 'status_message'
      params['status_message'].should == 'swipe accepted' 
    end

    it "fails without a signature" do
      post '/store/card', @query
      last_response.status.should == 400  
    end

    it "rejects swipe with incorrect signature" do
      post '/store/card', @incorrectly_signed_query
      last_response.status.should == 401  
    end

    it "makes the data available in redis" do
      post '/store/card', @signed_query
      cc = CreditCard.new({}, DEC_SECRET) 
      cc.get_from_redis
      cc.decrypt
      cc.data.should == @cc_data
    end

  end

  describe "availability to client" do

    it "requires a card_token" do
      get '/store/request_card_swipe'
      params = JSON.parse(last_response.body) 
      params.should include 'card_token'
      params['card_token'].should be_a_kind_of String
      card_token = params['card_token']

      post '/store/card', @signed_query
      pp last_response unless last_response.status == 200
      last_response.status.should == 200  
      params = JSON.parse(last_response.body) 
      params.should include 'status_message'
      params['status_message'].should == 'swipe accepted' 

      get '/store/read_card_swipe', {:card_token => card_token}
      params = JSON.parse(last_response.body) 
      params.should include 'status_message'
      params['status_message'].should == 'card available'
      params.should include 'name'
      params.should include 'last4'
    end

    it "returns an email for existing customer" do
      r = rand(100000)
      @cc_data = { 
        :timestamp => Time.now.to_i.to_s, 
        :name => "Test#{r}/ User J",
        :number => '1023102310231023',
        :exp_month => '12',
        :exp_year => '2014'
      }
      cc = CreditCard.new( @cc_data, ENC_SECRET )
      signed_query = CreditCard.add_signature({:data => cc.encrypted},AES_PASSPHRASE)

      c = Customer.new()
      c.cc_name = @cc_data[:name]
      c.email = "Test#{r}@email.com"
      c.save

      get '/store/request_card_swipe'
      params = JSON.parse(last_response.body) 
      params.should include 'card_token'
      params['card_token'].should be_a_kind_of String
      card_token = params['card_token']

      post '/store/card', signed_query
      pp last_response unless last_response.status == 200
      last_response.status.should == 200  
      params = JSON.parse(last_response.body) 
      params.should include 'status_message'
      params['status_message'].should == 'swipe accepted' 

      get '/store/read_card_swipe', {:card_token => card_token}
      params = JSON.parse(last_response.body) 
      params.should include 'status_message'
      params['status_message'].should == 'card available'
      params.should include 'name'
      params.should include 'last4'
      params.should include 'email'
      params['email'].should == c.email
      params['name'].should == c.cc_name
    end


  end
    
end


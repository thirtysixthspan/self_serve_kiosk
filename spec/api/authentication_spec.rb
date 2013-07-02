require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../auth_helper'

describe 'Authenticating to the API' do
  include Rack::Test::Methods
  include AuthHelper
  def app
    Sinatra::Application
  end  
  before :all do
    auth_login
  end

  it 'requires valid credentials' do
    get '/api', {}, @headers
    last_response.status.should == 200
  end                                      

  it 'fails without credentials' do
    get '/api'
    last_response.status.should == 401
  end
                                          
end

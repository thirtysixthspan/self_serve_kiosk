require File.join(File.dirname(__FILE__), '..', 'main.rb')

require 'sinatra'
require 'rack/test'
require 'rspec'

set :environment, :test

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.mock_with :rspec

end


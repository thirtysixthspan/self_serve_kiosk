require './main'
require 'rack/contrib'
use Rack::Evil
run Sinatra::Application

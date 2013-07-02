require 'sinatra'
require 'sass'
require 'haml'
require 'yaml'
require 'rack/contrib'
require 'redis'
require 'uuidtools'
require 'json'
require 'stripe'
require 'pp'
require 'logger'
require 'pony'
require 'sanitize'
require 'sinatra/content_for'
require 'active_support/core_ext/hash'
require 'time'
require 'fileutils'

require './lib/customer.rb'
require './lib/invoice.rb'
require './lib/invoice_order_list.rb'
require './lib/credit_card.rb'
require './lib/signature.rb'
require './lib/order.rb'

require './lib/event.rb'
require './lib/person.rb'
require './lib/attendee_list.rb'
require './lib/ban_list.rb'
require './lib/leader_list.rb'
require './lib/member_list.rb'
require './lib/registration_confirmation.rb'

require './lib/helpers.rb'

helpers do
  include Haml::Helpers
end  

$models = [
  'Customer',
  'Invoice',
  'InvoiceOrderList',
  'Order',
  'Event',
  'Person',
  'AttendeeList',
  'BanList',
  'LeaderList',
  'MemberList',
  'RegistrationConfirmation'
]

set :run, true
set :views, File.dirname(__FILE__) + "/views"
set :public_folder, File.dirname(__FILE__) + "/public"
set :logging, true

configure :development do
  INVOICE_PATH = "/tmp"
  CHARGE_PATH = "/tmp"
  ORDER_PATH = "/tmp"
  STRIPE_MODE = 'test'
  set :show_exceptions, true
  puts "Development Mode"
  AES_PASSPHRASE = 'secret_passphrase_must_replace'
  DEC_SECRET = load_private_key('/tmp/private.yaml')   
  DEVELOPMENT = true
end

configure :production do
  INVOICE_PATH = "/srv/www/self_service_kiosk.com/invoices"
  CHARGE_PATH = "/srv/www/self_service_kiosk.com/charges"
  ORDER_PATH = "/srv/www/self_service_kiosk.com/orders"
  STRIPE_MODE = 'live'
  set :dump_errors, false
  set :raise_errors, false  
  set :show_exceptions, false
  puts "Production Mode"
  DEC_SECRET = load_private_key()   
  DEVELOPMENT = false
end


APP_SIGNATURE = 'this is a unique and secret signature for signing forms'

STRIPE = YAML::load(File.new("./config/stripe.yaml",'r'))
Stripe.api_key = STRIPE["#{STRIPE_MODE}_secret_key"]

ITEMS_FOR_SALE = YAML::load(File.new("./conf/items_for_sale.yaml",'r'))

LOG = Logger.new(STDOUT)

REDIS = Redis.new(:host => "127.0.0.1", :port => 6379)
  
before do
  @hostname = request.host
  @page = request.path
end

get '/css/style.css' do
  scss "style".to_sym, :style => :expanded
end

get '/css/store.css' do
  scss :store, :style => :expanded
end

get '/css/events.css' do
  scss :events, :style => :expanded
end

get '/css/admin.css' do
  scss :'admin/style', :style => :expanded
end

get '/error' do
  haml "error".to_sym, :layout => "layout".to_sym
end


require './routes/about.rb'
require './routes/memberships.rb'
require './routes/terms_of_service.rb'
require './routes/privacy_policy.rb'
require './routes/copyright_policy.rb'
require './routes/terms_of_service.rb'
require './routes/facility_rules.rb'
require './routes/network_rules.rb'
require './routes/facility.rb'

get '/' do
  @page = 'home'
  haml :index, :layout => :layout  
end

require './methods/customer_charge_get'
require './methods/customer_charge_post'
require './methods/customer_list_get'
require './methods/customer_post'
require './methods/customer_put'
require './methods/customer_get'
require './methods/customer_delete'

require './routes/store/card'
require './routes/store/purchase'

require './routes/events/calendar'
require './routes/events/registration'

require './routes/admin/inspect'
require './routes/admin/record_operations'
require './routes/admin/panel'
require './routes/admin/invoicing'

get 'store' do
  redirect '/store/welcome'
end

get '/api' do
  protected!
  haml :api, :layout => :layout  
end

error do
  error = request.env['sinatra.error']
  Pony.mail({ :to => 'admin@self_service_kiosk.com',
              :from => "exception@#{@hostname}",
              :subject => "Exception occured on #{@hostname}: #{error.message}",
              :body => env.to_a.join("\n") + "\n" + error.backtrace.join("\n") 
  })  
  redirect('http://self_service_kiosk.com/')
end

get '/500' do
  raise 'error 500 page exception'
end

get '*' do
  haml :not_found, :layout => :layout
end

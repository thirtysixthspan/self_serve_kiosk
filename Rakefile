require 'redis'
require './lib/member_list.rb'
require './lib/leader_list.rb'
require './lib/ban_list.rb'
require './lib/person.rb'
require './lib/customer.rb'
require './lib/order.rb'
require './lib/invoice.rb'
require 'logger'
LOG = Logger.new(STDOUT)

  INVOICE_PATH = "/tmp"
  CHARGE_PATH = "/tmp"
  ORDER_PATH = "/tmp"
  STRIPE_MODE = 'test'
  DEVELOPMENT = true

require 'stripe'
STRIPE = YAML::load(File.new("./config/stripe.yaml",'r'))
Stripe.api_key = STRIPE["#{STRIPE_MODE}_secret_key"]

require 'pp'

task :test do 
  system ('rspec -fd .')
end

namespace "db" do
  
  namespace "rebuild" do
 
    task :ban_list do
      BanList.rebuild()
    end

    task :member_list do
      MemberList.rebuild()
    end

    task :leader_list do
      LeaderList.rebuild()
    end

    task :lists do
      MemberList.rebuild()
      LeaderList.rebuild()
      BanList.rebuild()    
    end

    task :admin do          
      p = Person.new()
      p.id = "Person:id:c616fe0f-3616-4265-97e2-9cd9c162c4b1"
      p.first_name = "Site"
      p.last_name = "Administrator"
      p.api_key = "fe724804-fc32-4e53-a834-de1a031d2dd5" 
      p.save
    end
    
    task :test_invoice do
      @person = Person.new()
      @person.set(
        :first_name=>'John',
        :last_name=>'Doe',
        :email=>'john.doe@gmail.com'
      ) 
      @person.save
      @customer = Customer.new(
        :cc_name => 'Doe/John',
        :email => 'john.doe@gmail.com',
        :member_id => @person.id
      )
      @customer.save
      success, id = @customer.obtain_stripe_token(
        :number => '4242424242424242',
        :exp_month => '12',
        :exp_year => '14',
        :cvc_code => '123'
      )
      success, id = @customer.create_stripe_customer
      @customer.save

      @order = Order.new(
        :completed => true,
        :customer_id => @customer.id,
        :timestamp => Time.now.to_i
      )
      @order.add(:price=>200,:name=>'Candy',:quantity=>2)
      @order.save

      @list = InvoiceOrderList.new(members: [@order]).save

      @invoice = Invoice.new(
        customer_id: @customer.id,
        invoice_order_list_id: @list.id,
        created_at: Time.now.to_i.to_s,
        tax_percent: "0.08375" ,
        membership_discount_percent: "0.10"
      ).save
    end

  end
 
  task :add_leader, :email, :first_name, :last_name, :member_number do |t, args|
    params = args.to_hash
    ll = LeaderList.first

    if !Person.exists?( :email => params[:email] )
      puts "Creating Person"
      p = Person.new()
      p.email = args[:email] if params.include?(:email)
      p.first_name = args[:first_name] if params.include?(:first_name)
      p.last_name = args[:last_name] if params.include?(:last_name)
      p.member_number = args[:member_number] if params.include?(:member_number)
      p.save
      ll.add(p.id)
      ll.save
    else
      puts "Sorry but that person exists"
    end

  end

  task :flush do
    redis = Redis.new(:host => "127.0.0.1", :port => 6379)
    redis.select(0)
    redis.flushdb
  end  

end

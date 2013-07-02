require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../auth_helper'

require 'capybara/rspec'

Capybara.app = Sinatra::Application

feature "Building monthly invoices" do
  include AuthHelper

  def build_order
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
    @customer.obtain_stripe_token(
      :number => '4242424242424242',
      :exp_month => '12',
      :exp_year => '14',
      :cvc_code => '123'
    )
    @customer.create_stripe_customer
    @customer.save

    @order = Order.new(
      :completed => true,
      :customer_id => @customer.id,
      :timestamp => Time.now.to_i
    )
    @order.add(:price=>200,:name=>'Candy',:quantity=>2)
    @order.save
  end

  def destroy_order
    @person.delete
    @customer.delete
    @order.delete
  end

  before :each do
  	clear_database
    build_order
    basic_auth
  end

  after :each do
  	destroy_order
  end

  scenario "build invoice for member" do

    visit "/admin/invoicing/build"

    @invoices = Invoice.where(customer_id: @customer.id)
    @invoices.size.should == 1
    @invoices.first.customer.should == @customer
    @invoices.first.invoice_order_list.members.first.should == @order
    @invoices.first.subtotal.should == 400
    @invoices.first.membership_discount.should == -40
    @invoices.first.tax.should == 30
    @invoices.first.total.should == 390
    File.exists?("#{INVOICE_PATH}/#{@invoices.first.uuid}.invoice").should == true
    @invoices.first.delete
  end

  scenario "build invoice for non-member" do

    @customer.member_id=nil
    @customer.save

    visit "/admin/invoicing/build"

    @invoices = Invoice.where(customer_id: @customer.id)
    @invoices.size.should == 1
    @invoices.first.customer.should == @customer
    @invoices.first.invoice_order_list.members.first.should == @order
    @invoices.first.subtotal.should == 400
    @invoices.first.membership_discount.should == -0
    @invoices.first.tax.should == 33
    @invoices.first.total.should == 433
    File.exists?("#{INVOICE_PATH}/#{@invoices.first.uuid}.invoice").should == true
    @invoices.first.delete
  end

end

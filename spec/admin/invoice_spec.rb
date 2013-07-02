require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../auth_helper'

require 'capybara/rspec'

Capybara.app = Sinatra::Application

feature "Invoicing opertions in admin interface" do
  include AuthHelper

  def build_invoice
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
    success.should == true
    success, id = @customer.create_stripe_customer
    success.should == true
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
    @invoice.log
  end

  def destroy_invoice
    @person.delete
    @customer.delete
    @order.delete
    @invoice.delete
  end

  before :each do
    clear_database
    build_invoice
    basic_auth
  end

  after :each do
    destroy_invoice
  end

  scenario "edit" do
    visit "/admin/edit/Person/#{@person.uuid}"

    fill_in 'Person[member_number]', :with => '12345678'

    click_on "Update"

    page.should have_content('12345678')

    person = Person.new(id: @person.id).load
    person.should be_a Person
    person.member_number.should == '12345678'
  end

  scenario "delete" do
    visit "/admin/inspect/Person/#{@person.uuid}"

    click_on "delete"

    person = Person.new(id: @person.id).load
    person.should == nil
  end

  scenario "email invoice" do

    FileUtils.rm "/tmp/last_email.html" if File.exists?("/tmp/last_email.html")

    visit "/admin/inspect/Invoice/#{@invoice.uuid}"

    click_on "email_invoice"

    File.exists?("/tmp/last_email.html").should == true
  end

  scenario "send charge confirmation email" do

    FileUtils.rm "/tmp/last_email.html" if File.exists?("/tmp/last_email.html")

    visit "/admin/inspect/Invoice/#{@invoice.uuid}"

    click_on "send_charge_confirmation"

    File.exists?("/tmp/last_email.html").should == true
  end

  scenario "charge_customer directly" do
    success, charge = @invoice.charge_card
    success.should == true
    @invoice.charge_status.should == true
  end

  scenario "charge_customer via admin interface" do

    visit "/admin/inspect/Invoice/#{@invoice.uuid}"

    click_on "charge_card"

    @invoice.load
    @invoice.charge_status.should == true
  end



end

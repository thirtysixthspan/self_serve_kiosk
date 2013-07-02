require File.dirname(__FILE__) + '/../spec_helper'
require 'capybara/rspec'
require 'capybara-webkit'

require './lib/credit_card.rb'
require 'yaml'

Capybara.app = Sinatra::Application
Capybara.javascript_driver = :webkit

def app
  Sinatra::Application
end

feature "Marking a purchase" do
  before :all do
  end

  scenario "adding an item to the order", :js => true do
    visit "/store/select_items"

    page.find("input[name='Energy Drinks']").value.should == '0'
    page.find("a.plus[name='Energy Drinks']").click
    page.find("input[name='Energy Drinks']").value.should == '1'

    page.click_button('Checkout')
    page.should have_content 'Energy Drinks'
  end


  scenario "adding multiple items to the order", :js => true do
    visit "/store/select_items"

    page.find("input[name='Energy Drinks']").value.should == '0'
    page.find("a.plus[name='Energy Drinks']").click
    page.find("a.plus[name='Energy Drinks']").click
    page.find("a.plus[name='Energy Drinks']").click
    page.find("input[name='Energy Drinks']").value.should == '3'

    page.click_button('Checkout')
    page.should have_content 'Energy Drinks'
    page.find("tr[name='Energy Drinks']").find("td.item_quantity").should have_content '3'
  end

  def post_credit_card(params={})
    r = rand(100000)
    cc_data = { 
      :timestamp => Time.now.to_i.to_s, 
      :name => "Test#{r}/ User J",
      :number => '4242424242424242',
      :exp_month => '12',
      :exp_year => '2014'
    }

    enc_secret = { 
      :aes_passphrase => AES_PASSPHRASE,
      :rsa_key => CreditCard.load_public_key(:passphrase => AES_PASSPHRASE, :key_file_name => "/tmp/public.yaml")
    }

    cc = CreditCard.new( cc_data, enc_secret )

    if params[:generate_customer]
      c = Customer.new()
      c.cc_name = cc_data[:name]
      c.email = "Test#{r}@email.com"
      c.save
    end

    signed_query = CreditCard.add_signature({:data => cc.encrypted},AES_PASSPHRASE)
    post '/store/card', signed_query
  end

  scenario "accepting a card swipe for an order", :js => true do

    visit "/store/select_items"

    page.find("a.plus[name='Candy']").click
    page.click_button('Checkout')
    page.click_button('Select Payment')
    sleep 4

    post_credit_card
    sleep 4

    page.should have_content '4242'    
    page.should have_content 'Test'    

  end

  scenario "autocompleting an email for an existing customer with a card swipe", :js => true do

    visit "/store/select_items"

    page.find("a.plus[name='Candy']").click
    page.click_button('Checkout')
    page.click_button('Select Payment')

    page.find('#name-input').value.should_not have_content 'Test'    
    page.find('#email-input').value.should_not have_content 'email.com'    
    sleep 4

    post_credit_card(:generate_customer => true)
    sleep 4

    page.find('#name-input').value.should have_content 'Test'    
    page.find('#email-input').value.should have_content 'email.com'    

  end


end

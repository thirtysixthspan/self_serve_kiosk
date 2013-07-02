require File.dirname(__FILE__) + '/../spec_helper'
require 'pp'
require 'capybara/rspec'

Capybara.app = Sinatra::Application

feature "Register for an event" do

  before :all do
    @e = Event.new()
    @e.title = "Test Event"
    @e.date = Time.local(2012,8,24,20,00).to_i
    @e.duration = 90*60 
    @e.url = "http://self_service_kiosk.com/"
    @e.location = "Lounge"
    @e.organizer_id = Person.new().save.id
    @e.attendee_list_id = AttendeeList.new().save.id
    @e.save
  end

  scenario "should send an invitation email" do

    visit "/events/registration/#{@e.uuid}"

    fill_in 'first_name', :with => 'John'
    fill_in 'last_name', :with => 'Doe'
    fill_in 'email', :with => 'john.doe@gmail.com'

    Pony.stub!(:deliver)
    Pony.should_receive(:mail) { |mail| 
      mail[:to].should == 'john.doe@gmail.com'
      true
    }
    click_on "Register"
    page.should have_content("Registration Confirmation Required")

    RegistrationConfirmation.all.each do |confirmation|
      if confirmation.person == Person.new(:email => 'john.doe@gmail.com')
        visit "/events/registration_confirmation/#{confirmation.uuid}"
        page.should have_content("Registration Complete")
      end  
    end

  end

  scenario "cannot be confirmed twice" do
    visit "/events/registration/#{@e.uuid}"

    fill_in 'first_name', :with => 'John'
    fill_in 'last_name', :with => 'Doe'
    email = "john.doe#{rand(10000)}@gmail.com"
    fill_in 'email', :with => email
    click_on "Register"
    page.should have_content("Registration Confirmation Required")

    RegistrationConfirmation.all.each do |confirmation|
      if confirmation.person == Person.new(:email => email)
        visit "/events/registration_confirmation/#{confirmation.uuid}"
        page.should have_content("Registration Complete")
      end  
    end

    RegistrationConfirmation.all.each do |confirmation|
      if confirmation.person == Person.new(:email => email)
        visit "/events/registration_confirmation/#{confirmation.uuid}"
        page.should have_content("Registration Error")
      end  
    end
  end

  scenario "cannot be completed twice" do
    visit "/events/registration/#{@e.uuid}"
    fill_in 'first_name', :with => 'John'
    fill_in 'last_name', :with => 'Doe'
    fill_in 'email', :with => 'john.doe@gmail.com'
    click_on "Register"
    page.should have_content("Registration Error")
  end

end

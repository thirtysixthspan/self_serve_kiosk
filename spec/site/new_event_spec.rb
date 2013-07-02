require File.dirname(__FILE__) + '/../spec_helper'

require 'capybara/rspec'

Capybara.app = Sinatra::Application

feature "Create a new public event" do

  before :all do
    @admin = Person.new()
    @admin.set(
      :first_name=>'Test',
      :last_name=>'Admin',
      :email=>'test.admin@gmail.com',
      :member_number=>'8512345'
    ) 
    @admin.save
    @leader_list = LeaderList.first
    @leader_list.add(@admin)
    @leader_list.save
    Event.all.each { |event| event.delete }
  end

  scenario "all fields correctly completed" do
    visit "/events/new_event"

    title = "Test Event #{rand(20000)}"
    fill_in 'title', :with => title
    fill_in 'url', :with => 'http://google.com'
    fill_in 'description', :with => 'This will be a great event.'
    fill_in 'date', :with => '8/31/12'
    select('1:30pm', :from => 'time')
    select('1 Hour', :from => 'duration')
    select('Lounge', :from => 'location')
    select('Public', :from => 'type')

    fill_in 'first_name', :with => 'Test'
    fill_in 'last_name', :with => 'Admin'
    fill_in 'email', :with => 'test.admin@gmail.com'
    fill_in 'member_number', :with => '8512345'

    click_on "Submit"

    page.should have_content("Register for an Event")
    page.should have_content(title)

    event = Event.new(:title => title).load
    event.should be_a Event
    (event.organizer === @admin).should == true
  end

end
